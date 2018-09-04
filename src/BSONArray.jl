
mutable struct BSONArray
    _wrap_::VoidPtr
    _ref_::Any

    function BSONArray()
        _wrap_ = ccall((:bson_new, libbson), VoidPtr, ())
        bsonArray = new(_wrap_, Union{})
        finalizer(destroy, bsonArray)
        bsonArray
    end

    function BSONArray(vec::Vector)
        bsonArray = BSONArray()
        for ele in vec
            append(bsonArray, ele)
        end
        bsonArray
    end

    function BSONArray(data::BytePtr, length::Integer, _ref_::Any)
        buffer = alloc_buf(128)
        ccall((:bson_init_static, libbson), Bool, (VoidPtr, BytePtr, UInt32),
              buffer, data, length) || error("bson_init_static: failure")
        b = Base.unsafe_convert(VoidPtr, buffer)
        new(b, (_ref_, buffer))
    end

    BSONArray(_wrap_::VoidPtr, _ref_::Any) = new(_wrap_, _ref_)
end
export BSONArray

@static if VERSION < v"0.7-"
Base.iteratoreltype(::Type{BSONArray}) = Base.EltypeUnknown()
else
Base.IteratorEltype(::Type{BSONArray}) = Base.EltypeUnknown()
end

function Base.convert(::Type{AbstractString}, bsonArray::BSONArray)
    cstr = ccall((:bson_array_as_json, libbson), BytePtr, (VoidPtr, BytePtr),
                 bsonArray._wrap_, C_NULL)
    cstr == C_NULL && return ""
    result = unsafe_string(cstr)
    ccall((:bson_free, libbson), Cvoid, (VoidPtr,), cstr)
    result
end

Base.convert(::Type{Array}, b::BSONArray) = collect(b)
Base.convert(::Type{Array{T}}, b::BSONArray) where {T} = collect(T, b)
Base.convert(::Type{Vector{T}}, b::BSONArray) where {T} = collect(T, b)

Base.string(bsonArray::BSONArray) = convert(AbstractString, bsonArray)

Base.show(io::IO, bsonArray::BSONArray) =
    print(io, "BSONArray($(convert(AbstractString, bsonArray)))")

Base.length(bsonArray::BSONArray) =
    ccall((:bson_count_keys, libbson), UInt32, (VoidPtr,), bsonArray._wrap_)

function append(bsonArray::BSONArray, val::Bool)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_bool, libbson), Bool, (VoidPtr, BytePtr, Cint, Bool),
          bsonArray._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonArray::BSONArray, val::Real)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_double, libbson), Bool, (VoidPtr, BytePtr, Cint, Cdouble),
          bsonArray._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonArray::BSONArray, val::DateTime)
    keyCStr = string(length(bsonArray))
    ts = round(Int64, datetime2unix(val)*1000)
    ccall((:bson_append_date_time, libbson), Bool, (VoidPtr, BytePtr, Cint, Clonglong),
          bsonArray._wrap_, keyCStr, length(keyCStr), ts) || bson_ovf()
end

append(bsonArray::BSONArray, val::Date) = append(bsonArray, DateTime(val))

function append(bsonArray::BSONArray, val::BSONArray)
    keyCStr = string(length(bsonArray))
    childBuffer = alloc_buf(128)
    ccall((:bson_append_array_begin, libbson), Bool, (VoidPtr, BytePtr, Cint, VoidPtr),
          bsonArray._wrap_, keyCStr, length(keyCStr), childBuffer) ||
              error("bson_append_array_begin: failure")
    childBSONArray = BSONArray(Base.unsafe_convert(VoidPtr, childBuffer), childBuffer)
    for element in val
        append(childBSONArray, element)
    end
    ccall((:bson_append_array_end, libbson), Bool, (VoidPtr, VoidPtr),
          bsonArray._wrap_, childBuffer) || error("bson_append_array_end: failure")
end

function append(bsonArray::BSONArray, val::Union{Int8, UInt8, Int16, UInt16, Int32, UInt32})
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_int32, libbson), Bool, (VoidPtr, BytePtr, Cint, Int32),
          bsonArray._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonArray::BSONArray, val::Union{Int64, UInt64})
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_int64, libbson), Bool, (VoidPtr, BytePtr, Cint, Int64),
          bsonArray._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonArray::BSONArray, val::BSONOID)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_oid, libbson), Bool, (VoidPtr, BytePtr, Cint, BytePtr),
          bsonArray._wrap_, keyCStr, length(keyCStr), val._wrap_) || bson_ovf()
end

function append(bsonArray::BSONArray, val::AbstractString)
    keyCStr = string(length(bsonArray))
    valUTF8 = String(val)
    ccall((:bson_append_utf8, libbson), Bool, (VoidPtr, BytePtr, Cint, BytePtr, Cint),
          bsonArray._wrap_, keyCStr, length(keyCStr), valUTF8, sizeof(valUTF8)) || bson_ovf()
end

append(bsonArray::BSONArray, val::Cvoid) = append_null(bsonArray)

function append(bsonArray::BSONArray, val::Symbol)
    if val == :null
        append_null(bsonArray)
    elseif val == :minkey
        append_minkey(bsonArray)
    elseif val == :maxkey
        append_maxkey(bsonArray)
    else
        append(bsonArray, string(val))
    end
end

function append(bsonArray::BSONArray, val::AbstractDict)
    keyCStr = string(length(bsonArray))
    childBuffer = alloc_buf(128)
    ccall((:bson_append_document_begin, libbson), Bool, (VoidPtr, BytePtr, Cint, VoidPtr),
          bsonArray._wrap_, keyCStr, length(keyCStr), childBuffer) ||
              error("bson_append_document_begin: failure")
    childBSONObject = BSONObject(Base.unsafe_convert(VoidPtr, childBuffer), childBuffer)
    for (k, v) in val
        append(childBSONObject, k, v)
    end
    ccall((:bson_append_document_end, libbson), Bool, (VoidPtr, VoidPtr),
          bsonArray._wrap_, childBuffer) || error("bson_append_document_end: failure")
end

function append(bsonArray::BSONArray, val::Vector)
    keyCStr = string(length(bsonArray))
    childBuffer = alloc_buf(128)
    ccall((:bson_append_array_begin, libbson), Bool, (VoidPtr, BytePtr, Cint, VoidPtr),
          bsonArray._wrap_, keyCStr, length(keyCStr), childBuffer) ||
              error("bson_append_array_begin: failure")
    childBSONArray = BSONArray(Base.unsafe_convert(VoidPtr, childBuffer), childBuffer)
    for element in val
        append(childBSONArray, element)
    end
    ccall((:bson_append_array_end, libbson), Bool, (VoidPtr, VoidPtr),
          bsonArray._wrap_, childBuffer) || error("bson_append_array_end: failure")
end

export append

function append_null(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_null, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonArray._wrap_, keyCStr, length(keyCStr)) || bson_ovf()
end
export append_null

function append_minkey(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_minkey, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonArray._wrap_, keyCStr, length(keyCStr)) || bson_ovf()
end
export append_minkey

function append_maxkey(bsonArray::BSONArray)
    keyCStr = string(length(bsonArray))
    ccall((:bson_append_maxkey, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonArray._wrap_, keyCStr, length(keyCStr)) || bson_ovf()
end
export append_maxkey

function vector(bsonArray::BSONArray)
    vec = Any[]
    for v in bsonArray
        if isa(v, BSONObject)
            push!(vec, dict(v))
        elseif isa(v, BSONArray)
            push!(vec, vector(v))
        else
            push!(vec, v)
        end
    end
    vec
end
export vector

# Private

destroy(bsonArray::BSONArray) =
    ccall((:bson_destroy, libbson), Cvoid, (VoidPtr,), bsonArray._wrap_)
