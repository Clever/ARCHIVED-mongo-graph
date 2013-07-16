_ = require 'underscore'
JSONStream = require 'JSONStream'
dotty = require 'dotty'

# proc = spawn 'dot', ['-Tpng', '-o', outPath]
# stream = proc.stdin
# proc.stderr.pipe process.stderr
stream = process.stdout
stream.write   """
  digraph {
    ranksep=4;
    rankdir=LR;
    concentrate=true;
    node [shape=box, style=filled];
    graph [overlap=false];\n
  """

process.stdin.pipe(JSONStream.parse()).on 'data', (data) ->

  # create/label/fill the node
  node_id = data._id.$oid
  stream.write "  \"#{node_id}\" [label=\"#{node_id}\",fillcolor=\"0 0.5 0.8\"];\n"

  # create edges out from this node
  links = _(dotty.deepKeys(data)).chain()
    .filter((key) -> _(key).last() is '$oid' and _(key).first() isnt '_id')
    .map((link_arr) -> link_arr[0..link_arr.length-2].join('.'))
    .value()
  for link in links
    dst = dotty.get(data, link).$oid
    stream.write "  \"#{node_id}\" -> \"#{dst}\" [style=solid, label=\"#{link}\", color=\"0 1 0.5\", fontcolor=\"0 1 0.5\"];\n"

.on 'end', () -> stream.write '}\n'
