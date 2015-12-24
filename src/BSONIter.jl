type BSONIter
    _wrap_::Vector{UInt8}
    done::Bool

    function BSONIter(bsonObject::BSONObject)
        bsonIter = new(Array(UInt8, 128), false)
        ccall(
            (:bson_iter_init, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            bsonObject._wrap_
            ) || error("BSONIter(): failure")
        bsonIter.done = !ccall(
            (:bson_iter_next, libbson),
            Bool, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
        return bsonIter
    end

    function BSONIter(bsonObject::BSONObject, key::AbstractString)
        bsonIter = new(Array(UInt8, 128), false)
        ccall(
            (:bson_iter_init, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            bsonObject._wrap_
            ) || error("BSONIter(): failure")
        keyCStr = bytestring(key)
        bsonIter.done = !ccall(
            (:bson_iter_find, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            keyCStr
            )
        return bsonIter
    end

    function BSONIter(bsonArray::BSONArray)
        bsonIter = new(Array(UInt8, 128), false)
        ccall(
            (:bson_iter_init, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            bsonArray._wrap_
            ) || error("BSONIter(): failure")
        bsonIter.done = !ccall(
            (:bson_iter_next, libbson),
            Bool, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
        return bsonIter
    end

    function BSONIter(bsonArray::BSONArray, key::Integer)
        bsonIter = new(Array(UInt8, 128), false)
        ccall(
            (:bson_iter_init, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            bsonArray._wrap_
            ) || error("BSONIter(): failure")
        keyCStr = bytestring(string(key))
        bsonIter.done = !ccall(
            (:bson_iter_find, libbson),
            Bool, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            keyCStr
            )
        return bsonIter
    end
end
export BSONIter

# Index

Base.getindex(bsonObject::BSONObject, key::AbstractString) = begin
    bsonIter = BSONIter(bsonObject, key)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

Base.getindex(bsonArray::BSONArray, key::Integer) = begin
    bsonIter = BSONIter(bsonArray, key - 1)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

# Associative collection

Base.get!(bsonObject::BSONObject, key::AbstractString, default) = begin
    iter = BSONIter(bsonObject, key)
    iter.done || return value(iter)
    append(bsonObject, key, default)
    return default
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
        (:bson_iter_key, libbson),
        Ptr{UInt8}, (Ptr{UInt8}, ),
        bsonIter._wrap_
        )
    cstr == C_NULL && error("bson_iter_key: failure")
    bytestring(cstr)
end

function value_type(bsonIter::BSONIter)
    bsonIter.done && error("alredy done iteration")
    return ccall(
        (:bson_iter_type, libbson),
        BSONType, (Ptr{UInt8}, ),
        bsonIter._wrap_
        )
end

done(bsonIter::BSONIter) = bsonIter.isDone
export done

function value(bsonIter::BSONIter)
    ty = value_type(bsonIter)
    if ty == BSON_TYPE_DOUBLE
        return ccall(
            (:bson_iter_double, libbson),
            Cdouble, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_INT32
        return ccall(
            (:bson_iter_int32, libbson),
            Int32, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_INT64
        return ccall(
            (:bson_iter_int64, libbson),
            Int64, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_BOOL
        return ccall(
            (:bson_iter_bool, libbson),
            Bool, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
    elseif ty == BSON_TYPE_DATE_TIME
        ts = ccall(
            (:bson_iter_date_time, libbson),
            Int64, (Ptr{UInt8}, ),
            bsonIter._wrap_
            )
        return Dates.unix2datetime(ts / 1000)
    elseif ty == BSON_TYPE_NULL
        return nothing
    elseif ty == BSON_TYPE_MINKEY
        return :minkey
    elseif ty == BSON_TYPE_MAXKEY
        return :maxkey
    elseif ty == BSON_TYPE_UTF8
        return utf8(bytestring(ccall(
            (:bson_iter_utf8, libbson),
            Ptr{UInt8}, (Ptr{UInt8}, Ptr{UInt8}),
            bsonIter._wrap_,
            C_NULL
            )))
    elseif ty == BSON_TYPE_OID
        return BSONOID(
            ccall(
                (:bson_iter_oid, libbson),
                Ptr{Void}, (Ptr{UInt8},),
                bsonIter._wrap_
                ),
            bsonIter
            )
    elseif ty == BSON_TYPE_DOCUMENT
        length = Array(UInt32, 1)
        data = Array(Ptr{UInt8}, 1)
        ccall(
            (:bson_iter_document, libbson),
            Ptr{Void}, (Ptr{UInt8}, Ptr{UInt32}, Ptr{Ptr{UInt8}}),
            bsonIter._wrap_, length, data
            )
        return BSONObject(data[1], length[1], bsonIter)
    elseif ty == BSON_TYPE_ARRAY
        length = Array(UInt32, 1)
        data = Array(Ptr{UInt8}, 1)
        ccall(
            (:bson_iter_array, libbson),
            Ptr{Void}, (Ptr{UInt8}, Ptr{UInt32}, Ptr{Ptr{UInt8}}),
            bsonIter._wrap_, length, data
            )
        return BSONArray(data[1], length[1], bsonIter)
    else
        error("unhandled BSONType $ty")
    end
end
export value

function next!(bsonIter::BSONIter)
    bsonIter.done = !ccall(
        (:bson_iter_next, libbson),
        Bool, (Ptr{UInt8}, ),
        bsonIter._wrap_
        )
    bsonIter
end
