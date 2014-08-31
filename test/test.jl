using FactCheck, LibBSON

facts("BSON") do
    bson = BSON()
    append_null(bson, "null")
    append(bson, "bool", true)
    append(bson, "int", 42)
    append(bson, "double", 3.141)
    append(bson, "string", "Hello, Jérôme")
    append_minkey(bson, "minkey")
    append_maxkey(bson, "maxkey")
    @fact convert(String, bson) => "{ \"null\" : null, \"bool\" : true, \"int\" : 42, \"double\" : 3.141000, \"string\" : \"Hello, Jérôme\", \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 } }"

    dict = Dict{Any, Any}()
    for (k, v) in bson
        dict[k] = v
    end
    @fact dict => {"int"=>42,"string"=>"Hello, Jérôme","minkey"=>:minkey,"double"=>3.141,"bool"=>true,"null"=>nothing,"maxkey"=>:maxkey}
end
