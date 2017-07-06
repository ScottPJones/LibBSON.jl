using FactCheck, LibBSON, Compat, DataStructures

facts("BSONOID") do
    oid = BSONOID()
    @fact length(string(oid)) --> 24
    @fact (oid == oid) --> true
    @fact typeof(hash(oid)) --> UInt
    oid2 = BSONOID()
    @fact (oid == oid2) --> false
    @fact string(BSONOID("540b628bca2e9b0d4e7dfa61")) --> "540b628bca2e9b0d4e7dfa61"
end

facts("BSONObject") do
    bsonObject = BSONObject(@compat Dict{Any,Any}(
        "null"=>nothing,
        "bool"=>true,
        "int"=>42,
        "double"=>0.125,
        "string"=>"Hello, Jérôme",
        "anotherNull"=>:null,
        "minkey"=>:minkey,
        "maxkey"=>:maxkey,
        "regularSymbol"=>:symbol,
        "binaryData"=>collect(map(t -> UInt8(t), 1:20)),
        "subdict"=> (@compat Dict{Any,Any}(
            "key"=>"value"
            )),
        "array"=> Any["hello", (@compat Dict{Any,Any}("foo" => Any[56, false]))]
        ))
    @fact length(bsonObject) --> 12
    @fact string(bsonObject) --> "{ \"string\" : \"Hello, Jérôme\", \"anotherNull\" : null, \"null\" : null, \"regularSymbol\" : \"symbol\", \"bool\" : true, \"int\" : 42, \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 }, \"binaryData\" : { \"\$binary\" : \"AQIDBAUGBwgJCgsMDQ4PEBESExQ=\", \"\$type\" : \"00\" }, \"array\" : [ \"hello\", { \"foo\" : [ 56, false ] } ], \"subdict\" : { \"key\" : \"value\" }, \"double\" : 0.125 }"
    @fact dict(bsonObject) --> @compat Dict{Any,Any}("string"=>"Hello, Jérôme","anotherNull"=>nothing,"null"=>nothing,"regularSymbol"=>"symbol","bool"=>true,"int"=>42,"minkey"=>:minkey,"maxkey"=>:maxkey,"binaryData"=>collect(map(t -> UInt8(t), 1:20)), "array"=>Any["hello",(@compat Dict{Any,Any}("foo"=>Any[56,false]))],"subdict"=>(@compat Dict{Any,Any}("key"=>"value")),"double"=>0.125)
    append(bsonObject, "int64", -57)
    @fact bsonObject["int64"] --> -57
    append(bsonObject, "int32", 0x12345678)
    @fact bsonObject["int32"] --> 305419896

    context("BSONObject Copy Constructor") do
        initialDict = Dict{Any,Any}("someText" => "hello")
        bsonObject = BSONObject(@compat initialDict)
        bsonObjectCopyBad  = bsonObject
        bsonObjectCopyGood = BSONObject(bsonObject)
        append(bsonObject, "someValue", -123.456)
        @fact dict(bsonObject)          --> not(initialDict)
        @fact dict(bsonObjectCopyBad)   --> not(initialDict)
        @fact dict(bsonObjectCopyGood)  --> initialDict
    end

    context("BSONObject with OID") do
        oid = BSONOID()
        bsonObject = BSONObject(@compat Dict{Any,Any}("oid" => oid))
        @fact (length(string(bsonObject)) > 0) --> true
        @fact (bsonObject["oid"] == oid) --> true
    end

    context("BSONObject with DateTime") do
        ts = now()
        d = Date()
        obj = BSONObject(@compat Dict("time" => ts, "date" => d))
        @fact obj["time"] --> ts
        @fact obj["date"] --> d
    end

    context("BSONObject from JSON") do
        @fact_throws BSONObject("invalid JSON")
        @fact string(BSONObject("{\"pi\": 0.125}")) --> "{ \"pi\" : 0.125 }"
    end

    context("BSONObject containing BSONObject") do
        subBSONObject = BSONObject(@compat Dict{Any,Any}("key"=>"value"))
        bsonObject = BSONObject(@compat Dict{Any,Any}("sub"=>subBSONObject))
        @fact string(bsonObject) --> "{ \"sub\" : { \"key\" : \"value\" } }"
        @fact string(bsonObject["sub"]) --> "{ \"key\" : \"value\" }"
    end
end

facts("BSONArray") do
    bsonArray = BSONArray([
        nothing,
        true,
        42,
        0.125,
        "Hello, Jérôme",
        :null,
        :minkey,
        :maxkey,
        :symbol
        ])
    @fact length(bsonArray) --> 9
    @fact string(bsonArray) --> "[ null, true, 42, 0.125, \"Hello, Jérôme\", null, { \"\$minKey\" : 1 }, { \"\$maxKey\" : 1 }, \"symbol\" ]"
    @fact vector(bsonArray) --> Any[nothing,true,42,0.125,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol"]
    append(bsonArray, BSONArray([false]))
    append(bsonArray, -67)
    append(bsonArray, ["hello", 6.7])
    @fact vector(bsonArray) --> Any[nothing,true,42,0.125,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol",Any[false],-67,["hello",6.7]]

    bsonArray = BSONArray()
    append(bsonArray, BSONOID())
    @fact length(bsonArray) --> 1

    context("Array of DateTimes") do
      ts = now()
      d = Date()
      arr = BSONArray([d,ts])
      @fact length(arr) --> 2
      @fact arr[1] --> d
      @fact arr[2] --> ts
      for i = 1:length(arr)
        @fact typeof(arr[i]) <: DateTime --> true
      end
    end
end

facts("BSONObject: get!") do
    bsonObject = BSONObject()
    @fact_throws bsonObject["foo"]
    @fact get!(bsonObject, "foo", true) --> true
    @fact get!(bsonObject, "foo", true) --> true
end

facts("BSONError") do
    err = BSONError()
    @fact typeof(string(err)) <: AbstractString --> true
end

facts("Issue 18") do
    @fact string(BSONObject(OrderedDict("a" => OrderedDict("b" => "c")))) --> "{ \"a\" : { \"b\" : \"c\" } }"
end
