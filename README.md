# mongo-graph

Visualizes connections between documents in a mongo database.

## Installation

    npm install mongo-graph -g

You also need ![GraphViz](http://www.graphviz.org/). On a Mac with homebrew you can `brew install graphviz`.

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

![](http://cl.ly/image/1z471T2s3d1u)

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

![](http://cl.ly/image/172o3M0l0z2y)


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

![](http://cl.ly/image/120q1j000h0U)
