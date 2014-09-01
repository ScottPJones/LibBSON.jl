type BSONIter
    _wrap_::Vector{Uint8}
    done::Bool

    function BSONIter(bsonObject::BSONObject)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bsonObject._wrap_
            ) || error("BSONIter(): failure")
        bsonIter.done = !ccall(
            (:bson_iter_next, BSON_LIB),
            Bool, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
        return bsonIter
    end

    function BSONIter(bsonObject::BSONObject, key::String)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bsonObject._wrap_
            ) || error("BSONIter(): failure")
        keyCStr = bytestring(key)
        bsonIter.done = !ccall(
            (:bson_iter_find, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            keyCStr
            )
        return bsonIter
    end

    function BSONIter(bsonArray::BSONArray)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bsonArray._wrap_
            ) || error("BSONIter(): failure")
        bsonIter.done = !ccall(
            (:bson_iter_next, BSON_LIB),
            Bool, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
        return bsonIter
    end

    function BSONIter(bsonArray::BSONArray, key::Integer)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bsonArray._wrap_
            ) || error("BSONIter(): failure")
        keyCStr = bytestring(string(key))
        bsonIter.done = !ccall(
            (:bson_iter_find, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            keyCStr
            )
        return bsonIter
    end
end
export BSONIter

# Index

Base.getindex(bsonObject::BSONObject, key::String) = begin
    bsonIter = BSONIter(bsonObject, key)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

Base.getindex(bsonArray::BSONArray, key::Integer) = begin
    bsonIter = BSONIter(bsonArray, key)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

# Iterator

start(bsonObject::BSONObject) = begin
    return BSONIter(bsonObject)
end
export start

next(bsonObject::BSONObject, bsonIter::BSONIter) = begin
    ((key(bsonIter), value(bsonIter)), next!(bsonIter))
end
export next

done(bsonObject::BSONObject, bsonIter::BSONIter) = begin
    bsonIter.done
end
export done

start(bsonArray::BSONArray) = begin
    return BSONIter(bsonArray)
end
export start

next(bsonArray::BSONArray, bsonIter::BSONIter) = begin
    (value(bsonIter), next!(bsonIter))
end
export next

done(bsonArray::BSONArray, bsonIter::BSONIter) = begin
    bsonIter.done
end
export done

# Private

function key(bsonIter::BSONIter)
    bsonIter.done && error("alredy done iteration")
    cstr = ccall(
        (:bson_iter_key, BSON_LIB),
        Ptr{Uint8}, (Ptr{Uint8}, ),
        bsonIter._wrap_
        )
    cstr == C_NULL && error("bson_iter_key: failure")
    bytestring(cstr)
end

function value_type(bsonIter::BSONIter)
    bsonIter.done && error("alredy done iteration")
    return ccall(
        (:bson_iter_type, BSON_LIB),
        BSONType, (Ptr{Uint8}, ),
        bsonIter._wrap_
        )
end

function value(bsonIter::BSONIter)
    ty = value_type(bsonIter)
    if ty == BSON_TYPE_DOUBLE
        return ccall(
            (:bson_iter_double, BSON_LIB),
            Cdouble, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_INT32
        return ccall(
            (:bson_iter_int32, BSON_LIB),
            Int32, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_INT64
        return ccall(
            (:bson_iter_int64, BSON_LIB),
            Int64, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_BOOL
        return ccall(
            (:bson_iter_bool, BSON_LIB),
            Bool, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_NULL
        return nothing
    elseif ty == BSON_TYPE_MINKEY
        return :minkey
    elseif ty == BSON_TYPE_MAXKEY
        return :maxkey
    elseif ty == BSON_TYPE_UTF8
        return utf8(bytestring(ccall(
            (:bson_iter_utf8, BSON_LIB),
            Ptr{Uint8}, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            C_NULL
            )))
    elseif ty == BSON_TYPE_OID
        return BSONOID(ccall(
            (:bson_iter_oid, BSON_LIB),
            Ptr{Void}, (Ptr{Uint8},),
            bsonIter._wrap_
            ))
    elseif ty == BSON_TYPE_DOCUMENT
        length = Array(Uint32, 1)
        data = Array(Ptr{Uint8}, 1)
        ccall(
            (:bson_iter_document, BSON_LIB),
            Ptr{Void}, (Ptr{Uint8}, Ptr{Uint32}, Ptr{Ptr{Uint8}}),
            bsonIter._wrap_, length, data
            )
        return BSONObject(data[1], length[1])
    elseif ty == BSON_TYPE_ARRAY
        length = Array(Uint32, 1)
        data = Array(Ptr{Uint8}, 1)
        ccall(
            (:bson_iter_array, BSON_LIB),
            Ptr{Void}, (Ptr{Uint8}, Ptr{Uint32}, Ptr{Ptr{Uint8}}),
            bsonIter._wrap_, length, data
            )
        return BSONArray(data[1], length[1])
    else
        error("unhandled BSONType $ty")
    end
end

function next!(bsonIter::BSONIter)
    bsonIter.done = !ccall(
        (:bson_iter_next, BSON_LIB),
        Bool, (Ptr{Uint8}, ),
        bsonIter._wrap_
        )
    bsonIter
end
