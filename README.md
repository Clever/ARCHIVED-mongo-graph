# mongo-graph

Visualizes connections between documents in a mongo database.

## Installation

    npm install mongo-graph -g

You also need [GraphViz](http://www.graphviz.org/). On a Mac with homebrew you can `brew install graphviz`.

## Basic Usage

```bash
mongo test-db --quiet --eval 'db.foo.remove(); db.foo.insert([
{
  "_id" : ObjectId("000000000000000000000001"),
  "other_foo" : ObjectId("000000000000000000000002")
},
{
  "_id" : ObjectId("000000000000000000000002"),
  "other_foo" : ObjectId("000000000000000000000001")
}])'
mongoexport --db test-db --collection foo | mongo-graph | dot -Tpng -o out.png && open out.png
```

![](http://f.cl.ly/items/0Q0f143u1M230l451z2t/out.png)

## Advanced usage

### Multiple collections

Data in a db often has links between documents in different collections. The output of `mongoexport` contains no data about the associated collection. However, mongo-graph can interpret a `__collection` field as metadata about which collection the json object belongs to. You can do this at the db level, or use a handy command-line json modifier like [jsontool](http://trentm.com/json/):

```bash
mongo test-db --quiet --eval 'db.foo.remove(); db.foo.insert([
{
  "_id" : ObjectId("000000000000000000000001"),
  "bar" : ObjectId("000000000000000000000003")
},
{
  "_id" : ObjectId("000000000000000000000002"),
  "bar" : ObjectId("000000000000000000000004")
}])'
mongo test-db --quiet --eval 'db.bar.remove(); db.bar.insert([
{
  "_id" : ObjectId("000000000000000000000003"),
},
{
  "_id" : ObjectId("000000000000000000000004"),
}])'
mongoexport --jsonArray --db test-db --collection foo | json -e 'this.__collection="foo"' > foo.in
mongoexport --jsonArray --db test-db --collection bar | json -e 'this.__collection="bar"' > bar.in
cat foo.in bar.in | mongo-graph | dot -Tpng -o out.png && open out.png
```

![](http://f.cl.ly/items/3J0z3Q3F2O342C3M2e0E/out.png)


### Custom node names

Labeling nodes by ObjectId is not very useful. You can override this default by attaching a `__label` field to your json objects:

```bash
mongo test-db --quiet --eval 'db.foo.remove(); db.foo.insert([
{
  "_id" : ObjectId("000000000000000000000001"),
  "bar" : ObjectId("000000000000000000000003"),
  "human_readable": "1"
},
{
  "_id" : ObjectId("000000000000000000000002"),
  "bar" : ObjectId("000000000000000000000004"),
  "human_readable": "2"
}])'
mongo test-db --quiet --eval 'db.bar.remove(); db.bar.insert([
{
  "_id" : ObjectId("000000000000000000000003"),
  "human_readable": "3"
},
{
  "_id" : ObjectId("000000000000000000000004"),
  "human_readable": "4"
}])'
mongoexport --jsonArray --db test-db --collection foo | json -e 'this.__collection="foo"; this.__label=this.human_readable' > foo.in
mongoexport --jsonArray --db test-db --collection bar | json -e 'this.__collection="bar"; this.__label=this.human_readable' > bar.in
cat foo.in bar.in | mongo-graph | dot -Tpng -o out.png && open out.png
```

![](http://f.cl.ly/items/0T020L3A1a1S1S2X3i3U/out.png)
