type BSON
    _wrap_::Ptr{Void}

    BSON() = begin
        _wrap_ = ccall(
            (:bson_new, BSON_LIB),
            Ptr{Void}, ()
            )
        bson = new(_wrap_)
        finalizer(bson, destroy)
        return bson
    end

    BSON(jsonString::String) = begin
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
        bson = new(_wrap_)
        finalizer(bson, destroy)
        return bson
    end

    BSON(data::Ptr{Uint8}, length::Uint32) = begin
        buffer = Array(Uint8, 128)
        ccall(
            (:bson_init_static, BSON_LIB),
            Bool, (Ptr{Void}, Ptr{Uint8}, Uint32),
            buffer, data, length
            ) || error("bson_init_static: failure")
        new(buffer)
    end

    BSON(_wrap_::Ptr{Void}) = new(_wrap_)
end
export BSON

function convert(::Type{String}, bson::BSON)
    cstr = ccall(
        (:bson_as_json, BSON_LIB),
        Ptr{Uint8}, (Ptr{Void}, Ptr{Uint8}),
        bson._wrap_,
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

string(bson::BSON) = convert(String, bson)

show(io::IO, bson::BSON) = print(io, "BSON($(convert(String, bson)))")
export show

function append(bson::BSON, key::String, val::Bool)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_bool, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Bool),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::Real)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_double, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Cdouble),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::BSON)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_document, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val._wrap_
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::Union(Int8, Uint8, Int16, Uint16, Int32, Uint32))
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_int32, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Int32),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::Union(Int64, Uint64))
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_int64, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Int64),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::BSONOID)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_oid, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        val._wrap_
        ) || error("libBSON: overflow")
end
function append(bson::BSON, key::String, val::String)
    keyCStr = bytestring(key)
    valUTF8 = utf8(val)
    ccall(
        (:bson_append_utf8, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint, Ptr{Uint8}, Cint),
        bson._wrap_,
        keyCStr,
        length(keyCStr),
        valUTF8,
        sizeof(valUTF8)
        ) || error("libBSON: overflow")
end
export append

function append_null(bson::BSON, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_null, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bson._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_null

function append_minkey(bson::BSON, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_minkey, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bson._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_minkey

function append_maxkey(bson::BSON, key::String)
    keyCStr = bytestring(key)
    ccall(
        (:bson_append_maxkey, BSON_LIB),
        Bool, (Ptr{Void}, Ptr{Uint8}, Cint),
        bson._wrap_,
        keyCStr,
        length(keyCStr)
        ) || error("libBSON: overflow")
end
export append_maxkey

# Private

function destroy(bson::BSON)
    ccall(
        (:bson_destroy, BSON_LIB),
        Void, (Ptr{Void},),
        bson._wrap_
        )
end
