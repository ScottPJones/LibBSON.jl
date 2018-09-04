
using LibBSON
@static if VERSION < v"0.7-"
    using Base.Test
else
    using Test
    using Dates
end

@testset "BSONOID" begin
    oid = BSONOID()
    @test length(string(oid)) == 24
    @test oid == oid
    @test isa(hash(oid), UInt)
    oid2 = BSONOID()
    @test oid != oid2
    @test string(BSONOID("540b628bca2e9b0d4e7dfa61")) == "540b628bca2e9b0d4e7dfa61"
end

@testset "BSONObject" begin
    bsonObject = BSONObject(Dict{Any,Any}(
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
        "subdict"=> (Dict{Any,Any}(
            "key"=>"value"
            )),
        "array"=> Any["hello", (Dict{Any,Any}("foo" => Any[56, false]))]
        ))
    @test length(bsonObject) == 12
    #@test string(bsonObject) == "{ \"string\" : \"Hello, Jérôme\", \"anotherNull\" : null, \"null\" : null, \"regularSymbol\" : \"symbol\", \"bool\" : true, \"int\" : 42, \"minkey\" : { \"\$minKey\" : 1 }, \"maxkey\" : { \"\$maxKey\" : 1 }, \"binaryData\" : { \"\$binary\" : \"AQIDBAUGBwgJCgsMDQ4PEBESExQ=\", \"\$type\" : \"00\" }, \"array\" : [ \"hello\", { \"foo\" : [ 56, false ] } ], \"subdict\" : { \"key\" : \"value\" }, \"double\" : 0.125 }"
    @test dict(bsonObject) == Dict{Any,Any}("string"=>"Hello, Jérôme","anotherNull"=>nothing,"null"=>nothing,"regularSymbol"=>"symbol","bool"=>true,"int"=>42,"minkey"=>:minkey,"maxkey"=>:maxkey,"binaryData"=>collect(map(t -> UInt8(t), 1:20)), "array"=>Any["hello",(Dict{Any,Any}("foo"=>Any[56,false]))],"subdict"=>(Dict{Any,Any}("key"=>"value")),"double"=>0.125)
    append(bsonObject, "int64", -57)
    @test bsonObject["int64"] == -57
    append(bsonObject, "int32", 0x12345678)
    @test bsonObject["int32"] == 305419896

    @testset "BSONObject Copy Constructor" begin
        initialDict = Dict{Any,Any}("someText" => "hello")
        bsonObject = BSONObject(initialDict)
        bsonObjectCopyBad  = bsonObject
        bsonObjectCopyGood = BSONObject(bsonObject)
        append(bsonObject, "someValue", -123.456)
        @test dict(bsonObject) != initialDict
        @test dict(bsonObjectCopyBad) != initialDict
        @test dict(bsonObjectCopyGood) == initialDict
    end

    @testset "BSONObject with OID" begin
        oid = BSONOID()
        bsonObject = BSONObject(Dict{Any,Any}("oid" => oid))
        @test length(string(bsonObject)) > 0
        @test bsonObject["oid"] == oid
    end

    @testset "BSONObject with DateTime" begin
        ts = now()
        d = Date()
        obj = BSONObject(Dict("time" => ts, "date" => d))
        @test obj["time"] == ts
        @test obj["date"] == d
    end

    @testset "BSONObject from JSON" begin
        @test_throws ErrorException BSONObject("invalid JSON")
        @test BSONObject("{\"pi\": 0.125}")["pi"] == 0.125
    end

    @testset "BSONObject containing BSONObject" begin
        subBSONObject = BSONObject(Dict{Any,Any}("key"=>"value"))
        bsonObject = BSONObject(Dict{Any,Any}("sub"=>subBSONObject))
        @test string(bsonObject) == "{ \"sub\" : { \"key\" : \"value\" } }"
        @test string(bsonObject["sub"]) == "{ \"key\" : \"value\" }"
    end
end

@testset "BSONArray" begin
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

    @test length(bsonArray) == 9
    #@test string(bsonArray) == "[ null, true, 42, 0.125, \"Hello, Jérôme\", null, { \"\$minKey\" : 1 }, { \"\$maxKey\" : 1 }, \"symbol\" ]"
    @test vector(bsonArray) == Any[nothing,true,42,0.125,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol"]
    append(bsonArray, BSONArray([false]))
    append(bsonArray, -67)
    append(bsonArray, ["hello", 6.7])
    @test vector(bsonArray) == Any[nothing,true,42,0.125,"Hello, Jérôme",nothing,:minkey,:maxkey,"symbol",Any[false],-67,["hello",6.7]]

    bsonArray = BSONArray()
    append(bsonArray, BSONOID())
    @test length(bsonArray) == 1

    @testset "Array of DateTimes" begin
      ts = now()
      d = Date()
      arr = BSONArray([d,ts])
      @test length(arr) == 2
      @test arr[1] == d
      @test arr[2] == ts

      for i = 1:length(arr)
        @test isa(arr[i], DateTime)
      end

    end
end

@testset "BSONObject: get!" begin
    bsonObject = BSONObject()
    @test_throws ErrorException bsonObject["foo"]
    @test get!(bsonObject, "foo", true)
    @test get!(bsonObject, "foo", true)
end

@testset "BSONError" begin
    err = BSONError()
    @test isa(string(err), AbstractString)
end

#@testset "Issue 18" begin
#    @test string(BSONObject(DataStructures.OrderedDict("a" => DataStructuresOrderedDict("b" => "c")))) --> "{ \"a\" : { \"b\" : \"c\" } }"
#end
