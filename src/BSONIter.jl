type BSONIter
    _wrap_::Vector{Uint8}
    done::Bool

    function BSONIter(bson::BSON)
        bsonIter = new(Array(Uint8, 128), false)
        ccall(
            (:bson_iter_init, BSON_LIB),
            Bool, (Ptr{Uint8}, Ptr{Uint8}),
            bsonIter._wrap_,
            bson._wrap_
            ) || error("BSONIter(): failure")
        bsonIter.done = !ccall(
            (:bson_iter_next, BSON_LIB),
            Bool, (Ptr{Uint8}, ),
            bsonIter._wrap_
            )
        return bsonIter
    end
end
export BSONIter

# Iterator

start(bson::BSON) = begin
    return BSONIter(bson)
end
export start

next(bson::BSON, bsonIter::BSONIter) = begin
    ((key(bsonIter), value(bsonIter)), next!(bsonIter))
end
export next

done(bson::BSON, bsonIter::BSONIter) = begin
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
    else
        error("unhandle BSONType $ty")
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
