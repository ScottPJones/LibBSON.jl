type BSONObject
    _wrap_::Ptr{Void}

    BSONObject() = begin
        _wrap_ = ccall(
            (:bson_new, BSON_LIB),
            Ptr{Void}, ()
            )
        bson = new(_wrap_)
        finalizer(bson, destroy)
        return bson
    end

    BSONObject(dict::Associative) = begin
        bson = BSONObject()
        for (k, v) in dict
            append(bson, k, v)
        end
        return bson
    end

    BSONObject(jsonString::String) = begin
        jsonCStr = bytestring(jsonString)
        bsonError = BSONError()
        _wrap_ = ccall(
            (:bson_new_from_json, BSON_LIB),
            Ptr{Void}, (Ptr{Uint8}, Csize_t, Ptr{Uint8}),
            jsonCStr,
            length(jsonCStr),
            bsonError._wrap_
            )
        _wrap_ != C_NULL || error(bsonError)
        bsonObject = new(_wrap_)
        finalizer(bsonObject, destroy)
        return bsonObject
    end

    BSONObject(data::Ptr{Uint8}, length::Integer) = begin
        buffer = Array(Uint8, 128)
        ccall(
            (:bson_init_static, BSON_LIB),
            Bool, (Ptr{Void}, Ptr{Uint8}, Uint32),
            buffer, data, length
            ) || error("bson_init_static: failure")
        new(buffer)
    end

    BSONObject(_wrap_::Ptr{Void}) = new(_wrap_)
end
export BSONObject

function convert(::Type{String}, bsonObject::BSONObject)
    cstr = ccall(
        (:bson_as_json, BSON_LIB),
        Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}),
        bsonObject._wrap_,
        C_NULL
        )
    result = bytestring(cstr)
    ccall(
        (:bson_free, BSON_LIB),
        Void, (Ptr{Void},),
        cstr
        )
    return result
end
export convert

string(bsonObject::BSONObject) = convert(String, bsonObject)

show(io::IO, bsonObject::BSONObject) = print(io, "BSONObject($(convert(String, bsonObject)))")
export show

function append(bsonObject::BSONObject, key::String, val::Bool)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_bool, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Bool),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::Real)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_double, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Cdouble),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::BSONObject)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_document, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val._wrap_
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::Union(Int8, Uint8, Int16, Uint16, Int32, Uint32))
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_int32, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Int32),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::Union(Int64, Uint64))
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_int64, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Int64),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::BSONOID)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_oid, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        val._wrap_
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::String)
    keyCStr = bytestring(key)
    valUTF8 = utf8(val)
    ccall(
        (:bson_append_utf8, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}, Cint),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        valUTF8,
        sizeof(valUTF8)
        ) || error("libBSON: overflow")
end
function append(bsonObject::BSONObject, key::String, val::Nothing)
    append_null(bsonObject, key)
end
function append(bsonObject::BSONObject, key::String, val::Symbol)
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
function append(bsonObject::BSONObject, key::String, val::Dict)
    keyCStr = bytestring(key)
    childBuffer = Array(Uint8, 128)
    ccall(
        (:bson_append_document_begin, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr),
        childBuffer
        ) || error("bson_append_document_begin: failure")
    childBSON = BSONObject(convert(Ptr{Void}, childBuffer))
    for (k, v) in val
        append(childBSON, k, v)
    end
    ccall(
        (:bson_append_document_end, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Void}),
        bsonObject._wrap_,
        childBuffer
        ) || error("bson_append_document_end: failure")
end
# function append(bsonObject::BSONObject, key::String, val::Vector)
#     keyCStr = bytestring(key)
#     childBuffer = Array(Uint8, 128)
#     ccall(
#         (:bson_append_array_begin, BSON_LIB),
#         Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Void}),
#         bsonObject._wrap_,
#         keyCStr,
#         length(keyCStr),
#         childBuffer
#         ) || error("bson_append_array_begin: failure")
#     childBSON = BSON(convert(Ptr{Void}, childBuffer))
#     for i = 1:length(val)
#         append(childBSON, string(i), val[i])
#     end
#     ccall(
#         (:bson_append_array_end, BSON_LIB),
#         Bool, (Ptr{Void}, Ptr{Void}),
#         bsonObject._wrap_,
#         childBuffer
#         ) || error("bson_append_array_end: failure")
# end
export append

function append_null(bsonObject::BSONObject, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_null, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_null

function append_minkey(bsonObject::BSONObject, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_minkey, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_minkey

function append_maxkey(bsonObject::BSONObject, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_maxkey, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bsonObject._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_maxkey

dict(bsonObject::BSONObject) = begin
    d = Dict{Any, Any}()
    for (k, v) in bsonObject
        if isa(v, BSONObject)
            d[k] = dict(v)
        else
            d[k] = v
        end
    end
    return d
end
export dict

# Private

function destroy(bsonObject::BSONObject)
    ccall(
        (:bson_destroy, BSON_LIB),
        Void, (Ptr{Void},),
        bsonObject._wrap_
        )
end
