#!/usr/bin/env bash

rm links.txt

# generates README images. "gem install cloudapp"

# 1
mongo test-db --quiet --eval 'db.foo.remove(); db.foo.insert([
{
  "_id" : ObjectId("000000000000000000000001"),
  "other_foo" : ObjectId("000000000000000000000002")
},
{
  "_id" : ObjectId("000000000000000000000002"),
  "other_foo" : ObjectId("000000000000000000000001")
}])'
mongoexport --db test-db --collection foo | ./cli.js | dot -Tpng -o out.png
cloudapp -d out.png >> temp.txt

# 2
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
cat foo.in bar.in | ./cli.js | dot -Tpng -o out.png
cloudapp -d out.png >> temp.txt

# 3
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
cat foo.in bar.in | ./cli.js | dot -Tpng -o out.png
cloudapp -d out.png >> temp.txt

cat temp.txt
