using FactCheck, LibBSON

facts("BSONOID") do
    oid = BSONOID()
    @fact length(string(oid)) => 24
    @fact (oid == oid) => true
    @fact typeof(hash(oid)) => Uint
    oid2 = BSONOID()
    @fact (oid == oid2) => false
end

facts("BSON") do
    bson = BSON()
    append_null(bson, "null")
    append(bson, "bool", true)
    append(bson, "int", 42)
    append(bson, "double", 3.141)
    append(bson, "string", "Hello, Jérôme")
    append_minkey(bson, "minkey")
    append_maxkey(bson, "maxkey")
    @fact string(bson) => "{ \"null\" : null, \"bool\" : true, \"int\" : 42, \"double\" : 3.141000, \"string\" : \"Hello, Jérôme\", \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 } }"

    dict = Dict{Any, Any}()
    for (k, v) in bson
        dict[k] = v
    end
    @fact dict => {"int"=>42,"string"=>"Hello, Jérôme","minkey"=>:minkey,"double"=>3.141,"bool"=>true,"null"=>nothing,"maxkey"=>:maxkey}

    context("BSON with OID") do
        bson = BSON()
        oid = BSONOID()
        append(bson, "oid", oid)
        @fact (length(string(bson)) > 0) => true
        @fact (bson["oid"] == oid) => true
    end

    context("BSON from JSON") do
        @fact_throws BSON("invalid JSON")
        @fact string(BSON("{\"pi\": 3.141}")) => "{ \"pi\" : 3.141000 }"
    end

    context("BSON containing BSON") do
        subBSON = BSON()
        append(subBSON, "key", "value")
        bson = BSON()
        append(bson, "sub", subBSON)
        @fact string(bson) => "{ \"sub\" : { \"key\" : \"value\" } }"
        @fact string(bson["sub"]) => "{ \"key\" : \"value\" }"
    end
end
