LibBSON.jl
==========

[![Build Status](https://api.travis-ci.org/pzion/LibBSON.jl.svg?branch=master)](https://travis-ci.org/pzion/LibBSON.jl)
[![Pkgs Status](http://pkg.julialang.org/badges/LibBSON.jl_release.svg)](http://pkg.julialang.org/?pkg=LibBSON.jl&ver=release)
[![Coverage Status](https://img.shields.io/coveralls/pzion/LibBSON.jl.svg)](https://coveralls.io/r/pzion/LibBSON.jl?branch=master)

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
