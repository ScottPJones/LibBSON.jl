
LibBSON.jl
==========

[![Build Status](https://api.travis-ci.org/ScottPJones/LibBSON.jl.svg?branch=master)](https://travis-ci.org/ScottPJones/LibBSON.jl)
[![0.6 Status](http://pkg.julialang.org/badges/LibBSON_0.6.svg)](http://pkg.julialang.org/?pkg=LibBSON)
[![Coverage Status](https://img.shields.io/coveralls/ScottPJones/LibBSON.jl.svg)](https://coveralls.io/r/ScottPJones/LibBSON.jl?branch=master)

[libbson](https://github.com/mongodb/libbson) bindings for [The Julia Language](http://julialang.org/)

License
-------

This software is licensed under the simplified BSD license; see the file LICENSE.md for details.


Example Usage
---------------

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
          "binaryData" => Array{UInt8}(20),
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

Please refer to the unit tests in test/runtests.jl for more examples of usage.


Contributing
------------

Contributions are welcome!  Please fork on github.com and submit a pull request if you have a contribution you think is worthwhile!
