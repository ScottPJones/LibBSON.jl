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
            },
        "array"=>{"hello", {"foo"=>{56,false}}}
        })
    @fact length(bsonObject) => 11
    @fact string(bsonObject) => "{ \"string\" : \"Hello, Jérôme\", \"anotherNull\" : null, \"null\" : null, \"regularSymbol\" : \"symbol\", \"bool\" : true, \"int\" : 42, \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 }, \"array\" : [ \"hello\", { \"foo\" : [ 56, false ] } ], \"subdict\" : { \"key\" : \"value\" }, \"double\" : 3.141000 }"
    @fact dict(bsonObject) => {"string"=>"Hello, Jérôme","anotherNull"=>nothing,"null"=>nothing,"regularSymbol"=>"symbol","bool"=>true,"int"=>42,"minkey"=>:minkey,"maxkey"=>:maxkey,"array"=>{"hello",{"foo"=>{56,false}}},"subdict"=>{"key"=>"value"},"double"=>3.141}

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

facts("BSONArray") do
    bsonArray = BSONArray([
        nothing,
        true,
        42,
        3.141,
        "Hello, Jérôme",
        :null,
        :minkey,
        :maxkey,
        :symbol
        ])
    @fact length(bsonArray) => 9
    @fact string(bsonArray) => "[ null, true, 42, 3.141000, \"Hello, Jérôme\", null, { \"\$minKey\" : 1 }, { \"\$maxKey\" : 1 }, \"symbol\" ]"
    @fact vector(bsonArray) => {nothing,true,42,3.141,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol"}
end
