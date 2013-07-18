_ = require 'underscore'
JSONStream = require 'JSONStream'
dotty = require 'dotty'
srand = require 'srand'
srand.seed 9
COLORS = [
  '#1abc9c'
  '#2ecc71'
  '#3498db'
  '#9b59b6'
  '#34495e'
  '#16a085'
  '#27ae60'
  '#2980b9'
  '#8e44ad'
  '#2c3e50'
  '#f1c40f'
  '#e67e22'
  '#e74c3c'
  '#ecf0f1'
  '#95a5a6'
  '#f39c12'
  '#d35400'
  '#c0392b'
  '#bdc3c7'
  '#7f8c8d'
]

rnd_color = () ->
  #("#{srand.random().toFixed(2)}" for i in [0..2]).join(' ')
  COLORS[Math.floor(srand.random() * COLORS.length)]

# tries to pick a color distinct from those in other_colors
distinct_color = (other_colors) ->
  loop # equiv to a do...until loop
    c = rnd_color()
    return c if (c not in other_colors) or (other_colors.length >= COLORS.length)

stream = process.stdout
stream.write   """
  digraph {
    ranksep=4;
    rankdir=LR;
    concentrate=true;
    node [shape=box, style=filled];
    graph [overlap=false];\n
  """

# collect __collection metadata attached to each object in order to draw subgraphs
collections = {} # e.g. # { "collection_name": { fillcolor: "...", nodes: [...] } ... }"
default_collection = fillcolor: rnd_color(), nodes: [] # backup for collection-less nodes

# store all edge info for writing/coloring correctly at the very end
# edges are colored w/ the same color as their dest node
edges = {} # e.g. { "<source_node_id>": [{label: "...", dest: "..."} ... ], ... }

# mapping from collection -> edge label -> color
edge_colors = {} # e.g. { "collection_name": { "im.a.nested.path": "#color", ... } ... }
default_edge_colors = {} # backup for when there's no collection name
# get a color for (collection, label) pairing, picking a new one if it hasn't
# already been picked
edge_color = (collection, label) ->
  label_map = 
    if collection?
      edge_colors[collection] ?= {}
      edge_colors[collection]
    else default_edge_colors
  # store a random color and return it
  label_map[label] ?= distinct_color _.values label_map

handle_data = (data) ->
  # all nodes keyed on objectid
  node_id = data._id.$oid
  node_label = data.__label or node_id

  if data.__collection?
    collections[data.__collection] ?= 
      fillcolor: distinct_color _(collections).pluck 'fillcolor'
      nodes: []
    collections[data.__collection].nodes.push node_id
    node_color = collections[data.__collection].fillcolor
  else
    default_collection.nodes.push node_id
    node_color = default_collection.fillcolor

  # create/label/fill the node
  stream.write "  \"#{node_id}\" [label=\"#{node_label}\", fillcolor=\"#{node_color}\", penwidth=0, fontname=\"helvetica\", fontcolor=white];\n"

  # store edges out from this node
  edge_labels = _(dotty.deepKeys(data)).chain()
    .filter((key) -> _(key).last() is '$oid' and _(key).first() isnt '_id')
    .map((link_arr) -> link_arr[0..link_arr.length-2].join('.'))
    .value()
  if edge_labels.length
    edges[node_id] = _(edge_labels).map (label) ->
      label: label
      dest: dotty.get(data, label).$oid
      color: edge_color data.__collection, label

was_seen = (node_id) ->
  _.some _.values(collections).concat([default_collection]), (c) ->
    _.contains c.nodes, node_id

process.stdin.pipe(JSONStream.parse()).on 'data', (data) ->
  # sometimes we get piped arrays, sometimes we get one json obj per line
  if _(data).isArray()
    handle_data d for d in data
  else
    handle_data data
.on 'end', () ->
  # draw edges
  for source, edgeinfos of edges
    # skipping any edges to nodes that we've never seen
    for edge in edgeinfos when was_seen edge.dest
      stream.write "  \"#{source}\" -> \"#{edge.dest}\" [style=solid, label=\"#{edge.label}\", color=\"#{edge.color}\", fontcolor=\"#{edge.color}\"];\n"

  # group together nodes in the same collection
  for cname, cinfo of collections
    stream.write "  subgraph #{cname} {\n"
    stream.write "    \"#{cname}\" [label=#{cname}, fillcolor=\"#{cinfo.fillcolor}\", penwidth=0, fontname=\"helvetica\", fontcolor=white];\n"
    stream.write "    rank=same;\n"
    stream.write "    \"#{node}\";\n" for node in cinfo.nodes
    stream.write "  }\n"
  stream.write '}\n'
