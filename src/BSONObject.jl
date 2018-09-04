export BSONObject, append, append_null, append_minkey, append_maxkey, dict

mutable struct BSONObject
    _wrap_::VoidPtr
    _owner_::Any

    function BSONObject()
        _wrap_ = ccall((:bson_new, libbson), VoidPtr, ())
        bsonObject = new(_wrap_, Union{})
        finalizer(destroy, bsonObject)
        bsonObject
    end

    function BSONObject(other::BSONObject)
        _owner_ = alloc_buf(128)
        ccall((:bson_copy_to, libbson), Cvoid, (VoidPtr, BytePtr), other._wrap_,
                pointer(_owner_))
        bsonObject = new(VoidPtr(pointer(_owner_)), _owner_)
        finalizer(destroy, bsonObject)
        bsonObject
    end

    function BSONObject(dict::AbstractDict)
        bsonObject = BSONObject()
        for (k, v) in dict
            append(bsonObject, k, v)
        end
        bsonObject
    end

    function BSONObject(jsonString::AbstractString)
        jsonCStr = string(jsonString)
        bsonError = BSONError()
        _wrap_ = ccall((:bson_new_from_json, libbson), VoidPtr, (BytePtr, Csize_t, BytePtr),
                       jsonCStr, length(jsonCStr), bsonError._wrap_)
        _wrap_ != C_NULL || error(bsonError)
        bsonObject = new(_wrap_, Union{})
        finalizer(destroy, bsonObject)
        bsonObject
    end

    function BSONObject(data::BytePtr, length::Integer, _ref_::Any)
        buffer = alloc_buf(128)
        ccall((:bson_init_static, libbson), Bool, (VoidPtr, BytePtr, UInt32),
            buffer, data, length) || error("bson_init_static: failure")
        b = Base.unsafe_convert(VoidPtr, buffer)
        new(b, (_ref_, buffer))
    end

    BSONObject(_wrap_::VoidPtr, _owner_::Any) = new(_wrap_, _owner_)
end

function Base.convert(::Type{AbstractString}, bsonObject::BSONObject)
    cstr = ccall((:bson_as_json, libbson), BytePtr, (VoidPtr, BytePtr),
                 bsonObject._wrap_, C_NULL)
    result = String(unsafe_string(cstr))
    ccall((:bson_free, libbson), Cvoid, (VoidPtr,), cstr)
    result
end

Base.string(bsonObject::BSONObject) = convert(AbstractString, bsonObject)

Base.show(io::IO, bsonObject::BSONObject) =
    print(io, "BSONObject($(convert(AbstractString, bsonObject)))")

Base.length(bsonObject::BSONObject) =
    ccall((:bson_count_keys, libbson), UInt32, (VoidPtr,), bsonObject._wrap_)

function append(bsonObject::BSONObject, key::AbstractString, val::Bool)
    keyCStr = string(key)
    ccall((:bson_append_bool, libbson), Bool, (VoidPtr, BytePtr, Cint, Bool),
          bsonObject._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end
function append(bsonObject::BSONObject, key::AbstractString, val::Real)
    keyCStr = string(key)
    ccall((:bson_append_double, libbson), Bool, (VoidPtr, BytePtr, Cint, Cdouble),
          bsonObject._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonObject::BSONObject, key::AbstractString, val::DateTime)
    keyCStr = string(key)
    ts = round(Int64, datetime2unix(val)*1000)
    ccall((:bson_append_date_time, libbson), Bool, (VoidPtr, BytePtr, Cint, Clonglong),
          bsonObject._wrap_, keyCStr, length(keyCStr), ts) || bson_ovf()
end

append(bsonObject::BSONObject, key::AbstractString, val::Date) =
    append(bsonObject, key, DateTime(val))

function append(bsonObject::BSONObject, key::AbstractString, val::BSONObject)
    keyCStr = string(key)
    ccall((:bson_append_document, libbson), Bool, (VoidPtr, BytePtr, Cint, BytePtr),
          bsonObject._wrap_, keyCStr, length(keyCStr), val._wrap_) || bson_ovf()
end

function append(bsonObject::BSONObject, key::AbstractString,
                val::Union{Int8, UInt8, Int16, UInt16, Int32, UInt32})
    keyCStr = string(key)
    ccall((:bson_append_int32, libbson), Bool, (VoidPtr, BytePtr, Cint, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonObject::BSONObject, key::AbstractString, val::Union{Int64, UInt64})
    keyCStr = string(key)
    ccall((:bson_append_int64, libbson), Bool, (VoidPtr, BytePtr, Cint, Clong),
          bsonObject._wrap_, keyCStr, length(keyCStr), val) || bson_ovf()
end

function append(bsonObject::BSONObject, key::AbstractString, val::BSONOID)
    keyCStr = string(key)
    ccall((:bson_append_oid, libbson), Bool, (VoidPtr, BytePtr, Cint, BytePtr),
          bsonObject._wrap_, keyCStr, length(keyCStr), val._wrap_) || bson_ovf()
end

append(bsonObject::BSONObject, key::AbstractString, val::Char) =
    append(bsonObject, key, string(val))

function append(bsonObject::BSONObject, key::AbstractString, val::AbstractString)
    keyCStr = string(key)
    valUTF8 = String(val)
    ccall((:bson_append_utf8, libbson), Bool, (VoidPtr, BytePtr, Cint, BytePtr, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr), valUTF8, sizeof(valUTF8)) || bson_ovf()
end

append(bsonObject::BSONObject, key::AbstractString, val::Cvoid) =
    append_null(bsonObject, key)

function append(bsonObject::BSONObject, key::AbstractString, val::Symbol)
    if val == :null
        append_null(bsonObject, key)
    elseif val == :minkey
        append_minkey(bsonObject, key)
    elseif val == :maxkey
        append_maxkey(bsonObject, key)
    else
        append(bsonObject, key, string(val))
    end
end

function append(bsonObject::BSONObject, key::AbstractString, val::AbstractDict)
    keyCStr = string(key)
    childBuffer = alloc_buf(128)
    ccall((:bson_append_document_begin, libbson), Bool, (VoidPtr, BytePtr, Cint, VoidPtr),
          bsonObject._wrap_, keyCStr, length(keyCStr), childBuffer) ||
              error("bson_append_document_begin: failure")
    childBSON = BSONObject(Base.unsafe_convert(VoidPtr, childBuffer), childBuffer)
    for (k, v) in val
        append(childBSON, k, v)
    end
    ccall((:bson_append_document_end, libbson), Bool, (VoidPtr, VoidPtr),
          bsonObject._wrap_, childBuffer) || error("bson_append_document_end: failure")
end

function append(bsonObject::BSONObject, key::AbstractString, valBinary::Vector{UInt8})
    keyCStr = string(key)
    ccall((:bson_append_binary, libbson), Bool,
          (VoidPtr, BytePtr, Cint, Cint, BytePtr, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr), 0, #BSON_SUBTYPE_BINARY
          valBinary, length(valBinary)) || bson_ovf()
end

function append(bsonObject::BSONObject, key::AbstractString, val::Vector)
    keyCStr = string(key)
    childBuffer = alloc_buf(128)
    ccall((:bson_append_array_begin, libbson), Bool, (VoidPtr, BytePtr, Cint, VoidPtr),
          bsonObject._wrap_, keyCStr, length(keyCStr), childBuffer) ||
              error("bson_append_array_begin: failure")
    childBSONArray = BSONArray(Base.unsafe_convert(VoidPtr, childBuffer), childBuffer)
    for element in val
        append(childBSONArray, element)
    end
    ccall((:bson_append_array_end, libbson), Bool, (VoidPtr, VoidPtr),
          bsonObject._wrap_, childBuffer) || error("bson_append_array_end: failure")
end

function append_null(bsonObject::BSONObject, key::AbstractString)
    keyCStr = string(key)
    ccall((:bson_append_null, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr)) || bson_ofv()
end

function append_minkey(bsonObject::BSONObject, key::AbstractString)
    keyCStr = string(key)
    ccall((:bson_append_minkey, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr)) || bson_ovf()
end

function append_maxkey(bsonObject::BSONObject, key::AbstractString)
    keyCStr = string(key)
    ccall((:bson_append_maxkey, libbson), Bool, (VoidPtr, BytePtr, Cint),
          bsonObject._wrap_, keyCStr, length(keyCStr)) || bson_ovf()
end

function dict(bsonObject::BSONObject)
    d = Dict{Any, Any}()
    @static VERSION < v"0.7-" || dump(bsonObject)
    for (k, v) in bsonObject
        if isa(v, BSONObject)
            d[k] = dict(v)
        elseif isa(v, BSONArray)
            d[k] = vector(v)
        else
            @static VERSION < v"0.7-" || println("k = $k, v = $v")
            d[k] = v
        end
    end
    d
end

# Private

destroy(bsonObject::BSONObject) =
    ccall((:bson_destroy, libbson), Cvoid, (VoidPtr,), bsonObject._wrap_)
