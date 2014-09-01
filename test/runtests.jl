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
    bson = BSON({
        "null"=>nothing,
        "bool"=>true,
        "int"=>42,
        "double"=>3.141,
        "string"=>"Hello, Jérôme",
        "anotherNull"=>:null,
        "minkey"=>:minkey,
        "maxkey"=>:maxkey,
        "regularSymbol"=>:symbol,
        "subdict"=>{
            "key"=>"value"
            }
        })
    @fact string(bson) => "{ \"int\" : 42, \"string\" : \"Hello, Jérôme\", \"minkey\" : { \"\$minKey\" : 1 }, \"regularSymbol\" : \"symbol\", \"anotherNull\" : null, \"subdict\" : { \"key\" : \"value\" }, \"double\" : 3.141000, \"bool\" : true, \"null\" : null, \"maxkey\" : { \"\$maxKey\" : 1 } }"
    @fact dict(bson) => {"int"=>42,"string"=>"Hello, Jérôme","minkey"=>:minkey,"regularSymbol"=>"symbol","anotherNull"=>nothing,"subdict"=>{"key"=>"value"},"double"=>3.141,"bool"=>true,"null"=>nothing,"maxkey"=>:maxkey}

    context("BSON with OID") do
        oid = BSONOID()
        bson = BSON({"oid"=>oid})
        @fact (length(string(bson)) > 0) => true
        @fact (bson["oid"] == oid) => true
    end

    context("BSON from JSON") do
        @fact_throws BSON("invalid JSON")
        @fact string(BSON("{\"pi\": 3.141}")) => "{ \"pi\" : 3.141000 }"
    end

    context("BSON containing BSON") do
        subBSON = BSON({"key"=>"value"})
        bson = BSON({"sub"=>subBSON})
        @fact string(bson) => "{ \"sub\" : { \"key\" : \"value\" } }"
        @fact string(bson["sub"]) => "{ \"key\" : \"value\" }"
    end
end
