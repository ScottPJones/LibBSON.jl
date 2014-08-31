LibBSON.jl
==========

[libbson](https://github.com/mongodb/libbson) bindings for [The Julia Language](http://julialang.org/)


License
-------

This software is licensed under a simplified BSD license; see the file LICENSE for details.


Installing
----------

You must have libbson installed; see https://github.com/mongodb/libbson for details.


Getting Started
---------------

    using LibBSON

    bson = BSON()
    append_null(bson, "null")
    append(bson, "bool", true)
    append(bson, "int", 42)
    append(bson, "double", 3.141)
    append(bson, "string", "Hello, Jérôme")
    append(bson, "oid", BSONOID())
    append_minkey(bson, "minkey")
    append_maxkey(bson, "maxkey")
    println(bson)
    println(bson["string"])
    for (k, v) in bson
        println("$k => $v")
    end


Contributing
------------

Contributions are welcome!  Please fork on github.com and submit a pull request if you have a contribution you think is worthwhile!
