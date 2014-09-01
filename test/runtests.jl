using FactCheck, LibBSON

facts("BSONOID") do
    oid = BSONOID()
    @fact length(string(oid)) => 24
    @fact (oid == oid) => true
    @fact typeof(hash(oid)) => Uint
    oid2 = BSONOID()
    @fact (oid == oid2) => false
end

facts("BSONObject") do
    bsonObject = BSONObject({
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
    @fact string(bsonObject) => "{ \"int\" : 42, \"string\" : \"Hello, Jérôme\", \"minkey\" : { \"\$minKey\" : 1 }, \"regularSymbol\" : \"symbol\", \"anotherNull\" : null, \"subdict\" : { \"key\" : \"value\" }, \"double\" : 3.141000, \"bool\" : true, \"null\" : null, \"maxkey\" : { \"\$maxKey\" : 1 } }"
    @fact dict(bsonObject) => {"int"=>42,"string"=>"Hello, Jérôme","minkey"=>:minkey,"regularSymbol"=>"symbol","anotherNull"=>nothing,"subdict"=>{"key"=>"value"},"double"=>3.141,"bool"=>true,"null"=>nothing,"maxkey"=>:maxkey}

    context("BSONObject with OID") do
        oid = BSONOID()
        bsonObject = BSONObject({"oid"=>oid})
        @fact (length(string(bsonObject)) > 0) => true
        @fact (bsonObject["oid"] == oid) => true
    end

    context("BSONObject from JSON") do
        @fact_throws BSONObject("invalid JSON")
        @fact string(BSONObject("{\"pi\": 3.141}")) => "{ \"pi\" : 3.141000 }"
    end

    context("BSONObject containing BSONObject") do
        subBSONObject = BSONObject({"key"=>"value"})
        bsonObject = BSONObject({"sub"=>subBSONObject})
        @fact string(bsonObject) => "{ \"sub\" : { \"key\" : \"value\" } }"
        @fact string(bsonObject["sub"]) => "{ \"key\" : \"value\" }"
    end
end
