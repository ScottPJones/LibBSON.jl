using LibBSON

bsonObject = BSONObject(Dict(
    "null" => nothing,
    "bool" => true,
    "int" => 42,
    "double" => 3.141,
    "string" => "Hello, Jérôme",
    "oid" => BSONOID(),
    "minkey" => :minkey,
    "maxkey" => :maxkey,
    "array" => Any[5.41, false]
    ))
println(bsonObject)
println(bsonObject["string"])
for (k, v) in bsonObject
    println("$k => $v")
end
bsonArray = BSONArray(Any[
    "one",
    Dict("key" => 6.7)
    ])
for e in bsonArray
    println(e)
end
