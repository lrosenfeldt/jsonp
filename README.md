# Jsonp

Parse json into an AST. Despite the setup, it will not be released a gem and you should be thankful for that. I wanted to learn ruby.

## Example

The AST itself it a collection of nodes. The 3 basic objects are:
1. `Jsonp::ValueNode` containing a primitive value, e.g. `nil`, `false`, `42`.
1. `Jsonp::ArrayNode` containing a value that is an array of more nodes
1. `Jsonp::ObjectNode` containing a value that is a hash of more nodes


```ruby
parser = Jsonp::Parser.new

ast = parser.parse %({ "name": "jsonp", "version": 14, "isDebug": true, "releaseUrl": null, "tags": ["json", "parser"] })
# Result
# Jsonp::ObjectNode
#   "name" => Jsonp::ValueNode "jsonp"
#   "version" => Jsonp::ValueNode 14
#   "isDebug" => Jsonp::ValueNode true
#   "releaseUrl" => Jsonp::ValueNode nil
#   "tags" => Jsonp::ArrayNode
#       0: Jsonp::ValueNode "json"
#       1: Jsonp::ValueNode "parser"
```
