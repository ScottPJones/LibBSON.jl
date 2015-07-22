using FactCheck, LibBSON

using LibBSON: Obj

facts("BSONOID") do
    oid = BSONOID()
    @fact length(string(oid)) => 24
    @fact (oid == oid) => true
    @fact typeof(hash(oid)) => Uint
    oid2 = BSONOID()
    @fact (oid == oid2) => false
    @fact string(BSONOID("540b628bca2e9b0d4e7dfa61")) => "540b628bca2e9b0d4e7dfa61"
end

facts("BSONObject") do
    bsonObject = BSONObject(Obj(
        "null"=>nothing,
        "bool"=>true,
        "int"=>42,
        "double"=>3.141,
        "string"=>"Hello, Jérôme",
        "anotherNull"=>:null,
        "minkey"=>:minkey,
        "maxkey"=>:maxkey,
        "regularSymbol"=>:symbol,
        "subdict"=> Obj(
            "key"=>"value"
            ),
        "array"=> Any["hello", Obj("foo" => Any[56, false])]
        ))
    @fact length(bsonObject) => 11
    @fact string(bsonObject) => "{ \"string\" : \"Hello, Jérôme\", \"anotherNull\" : null, \"null\" : null, \"regularSymbol\" : \"symbol\", \"bool\" : true, \"int\" : 42, \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 }, \"array\" : [ \"hello\", { \"foo\" : [ 56, false ] } ], \"subdict\" : { \"key\" : \"value\" }, \"double\" : 3.141000 }"
    @fact dict(bsonObject) => Obj("string"=>"Hello, Jérôme","anotherNull"=>nothing,"null"=>nothing,"regularSymbol"=>"symbol","bool"=>true,"int"=>42,"minkey"=>:minkey,"maxkey"=>:maxkey,"array"=>Any["hello",Obj("foo"=>Any[56,false])],"subdict"=>Obj("key"=>"value"),"double"=>3.141)
    append(bsonObject, "int64", -57)
    @fact bsonObject["int64"] => -57
    append(bsonObject, "int32", 0x12345678)
    @fact bsonObject["int32"] => 305419896

    context("BSONObject with OID") do
        oid = BSONOID()
        bsonObject = BSONObject(Obj("oid" => oid))
        @fact (length(string(bsonObject)) > 0) => true
        @fact (bsonObject["oid"] == oid) => true
    end

    context("BSONObject from JSON") do
        @fact_throws BSONObject("invalid JSON")
        @fact string(BSONObject("{\"pi\": 3.141}")) => "{ \"pi\" : 3.141000 }"
    end

    context("BSONObject containing BSONObject") do
        subBSONObject = BSONObject(Obj("key"=>"value"))
        bsonObject = BSONObject(Obj("sub"=>subBSONObject))
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
    @fact vector(bsonArray) => Any[nothing,true,42,3.141,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol"]
    append(bsonArray, BSONArray([false]))
    append(bsonArray, -67)
    append(bsonArray, ["hello", 6.7])
    @fact vector(bsonArray) => Any[nothing,true,42,3.141,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol",Any[false],-67,["hello",6.7]]

    bsonArray = BSONArray()
    append(bsonArray, BSONOID())
    @fact length(bsonArray) => 1
end

facts("BSONObject: get!") do
    bsonObject = BSONObject()
    @fact_throws bsonObject["foo"]
    @fact get!(bsonObject, "foo", true) => true
    @fact get!(bsonObject, "foo", true) => true
end
