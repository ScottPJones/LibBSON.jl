
mutable struct BSONIter
    _wrap_::Vector{UInt8}
    done::Bool

    function BSONIter(bsonObject::BSONObject)
        bsonIter = new(alloc_buf(128), false)
        ccall((:bson_iter_init, libbson), Bool, (BytePtr, BytePtr),
              bsonIter._wrap_, bsonObject._wrap_) || error("BSONIter(): failure")
        bsonIter.done = !ccall((:bson_iter_next, libbson), Bool, (BytePtr, ), bsonIter._wrap_)
        bsonIter
    end

    function BSONIter(bsonObject::BSONObject, key::AbstractString)
        bsonIter = new(alloc_buf(128), false)
        ccall((:bson_iter_init, libbson), Bool, (BytePtr, BytePtr),
              bsonIter._wrap_, bsonObject._wrap_) || error("BSONIter(): failure")
        keyCStr = string(key)
        bsonIter.done = !ccall((:bson_iter_find, libbson), Bool, (BytePtr, BytePtr),
                               bsonIter._wrap_, keyCStr)
        bsonIter
    end

    function BSONIter(bsonArray::BSONArray)
        bsonIter = new(alloc_buf(128), false)
        ccall((:bson_iter_init, libbson), Bool, (BytePtr, BytePtr),
              bsonIter._wrap_, bsonArray._wrap_) || error("BSONIter(): failure")
        bsonIter.done = !ccall((:bson_iter_next, libbson), Bool, (BytePtr, ), bsonIter._wrap_)
        bsonIter
    end

    function BSONIter(bsonArray::BSONArray, key::Integer)
        bsonIter = new(alloc_buf(128), false)
        ccall((:bson_iter_init, libbson), Bool, (BytePtr, BytePtr),
              bsonIter._wrap_, bsonArray._wrap_) || error("BSONIter(): failure")
        keyCStr = string(key)
        bsonIter.done = !ccall((:bson_iter_find, libbson), Bool, (BytePtr, BytePtr),
                               bsonIter._wrap_, keyCStr)
        bsonIter
    end
end
export BSONIter

# Index

function Base.getindex(bsonObject::BSONObject, key::AbstractString)
    bsonIter = BSONIter(bsonObject, key)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

function Base.getindex(bsonArray::BSONArray, key::Integer)
    bsonIter = BSONIter(bsonArray, key - 1)
    bsonIter.done && error("key not found: $(repr(key))")
    value(bsonIter)
end

# Associative collection

function Base.get!(bsonObject::BSONObject, key::AbstractString, default)
    iter = BSONIter(bsonObject, key)
    iter.done || return value(iter)
    append(bsonObject, key, default)
    default
end

# Iterator

@static if VERSION < v"0.7-"
Base.start(bsonObject::BSONObject) = BSONIter(bsonObject)

Base.next(bsonObject::BSONObject, bsonIter::BSONIter) =
    ((key(bsonIter), value(bsonIter)), next!(bsonIter))

Base.done(bsonObject::BSONObject, bsonIter::BSONIter) = bsonIter.done

Base.start(bsonArray::BSONArray) = BSONIter(bsonArray)

Base.next(bsonArray::BSONArray, bsonIter::BSONIter) = (value(bsonIter), next!(bsonIter))

Base.done(bsonArray::BSONArray, bsonIter::BSONIter) = bsonIter.done
else
Base.iterate(bsonObject::BSONObject) = BSONIter(bsonObject)
Base.iterate(bsonArray::BSONArray)   = BSONIter(bsonArray)

Base.iterate(bsonObject::BSONObject, iter::BSONIter) = ((key(iter), value(iter)), next!(iter))
Base.iterate(bsonArray::BSONArray,   iter::BSONIter) = (value(iter), next!(iter))
end

# Private

function key(bsonIter::BSONIter)
    bsonIter.done && error("already done iteration")
    cstr = ccall((:bson_iter_key, libbson), BytePtr, (BytePtr, ), bsonIter._wrap_)
    cstr == C_NULL && error("bson_iter_key: failure")
    String(unsafe_string(cstr))
end

function value_type(bsonIter::BSONIter)
    bsonIter.done && error("already done iteration")
    ccall((:bson_iter_type, libbson), BSONType, (BytePtr, ), bsonIter._wrap_)
end

function value(bsonIter::BSONIter)
    ty = value_type(bsonIter)
    if ty == BSON_TYPE_DOUBLE
        ccall((:bson_iter_double, libbson), Cdouble, (BytePtr, ), bsonIter._wrap_)
    elseif ty == BSON_TYPE_INT32
        ccall((:bson_iter_int32, libbson), Int32, (BytePtr, ), bsonIter._wrap_)
    elseif ty == BSON_TYPE_INT64
        ccall((:bson_iter_int64, libbson), Int64, (BytePtr, ), bsonIter._wrap_)
    elseif ty == BSON_TYPE_BOOL
        ccall((:bson_iter_bool, libbson), Bool, (BytePtr, ), bsonIter._wrap_)
    elseif ty == BSON_TYPE_DATE_TIME
        ts = ccall((:bson_iter_date_time, libbson), Int64, (BytePtr, ), bsonIter._wrap_)
        Dates.unix2datetime(ts / 1000)
    elseif ty == BSON_TYPE_NULL
        nothing
    elseif ty == BSON_TYPE_MINKEY
        :minkey
    elseif ty == BSON_TYPE_MAXKEY
        :maxkey
    elseif ty == BSON_TYPE_UTF8
        String(unsafe_string(ccall((:bson_iter_utf8, libbson), BytePtr,
                                   (BytePtr, BytePtr), bsonIter._wrap_, C_NULL)))
    elseif ty == BSON_TYPE_OID
        data = alloc_buf(12)
        ptr = ccall((:bson_iter_oid, libbson), BytePtr, (BytePtr,), bsonIter._wrap_)
        unsafe_copyto!(pointer(data), ptr, 12)
        BSONOID(data)
    elseif ty == BSON_TYPE_DOCUMENT
        rlen = Ref{UInt32}(0)
        data = Ref{BytePtr}(C_NULL)
        ccall((:bson_iter_document, libbson), VoidPtr,
              (BytePtr, Ref{UInt32}, Ref{BytePtr}),
              bsonIter._wrap_, rlen, data)
        BSONObject(data[], rlen[], bsonIter)
    elseif ty == BSON_TYPE_ARRAY
        rlen  = Ref{UInt32}(0)
        data = Ref{BytePtr}(C_NULL)
        ccall((:bson_iter_array, libbson), VoidPtr,
              (BytePtr, Ref{UInt32}, Ref{BytePtr}),
              bsonIter._wrap_, rlen, data)
        BSONArray(data[], rlen[], bsonIter)
    elseif ty == BSON_TYPE_BINARY
        rlen = Ref{UInt32}(0)
        data = Ref{BytePtr}(C_NULL)
        ccall((:bson_iter_binary, libbson), VoidPtr,
              (BytePtr, VoidPtr, Ref{UInt32}, Ref{BytePtr}),
              bsonIter._wrap_, C_NULL, rlen, data)
        len = Int(rlen[])
        dataArray = alloc_buf(len)
        unsafe_copyto!(pointer(dataArray), data[], len)
        dataArray
    else
        error("unhandled BSONType $ty")
    end
end
export value

function next!(bsonIter::BSONIter)
    bsonIter.done = !ccall((:bson_iter_next, libbson), Bool, (BytePtr, ), bsonIter._wrap_)
    bsonIter
end
