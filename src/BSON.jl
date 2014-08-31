type BSON
    _wrap_::Ptr{Uint8}

    function BSON(jsonString::String)
        jsonCStr = bytestring(jsonString)
        bsonError = BSONError()
        _wrap_ = ccall(
            (:bson_new_from_json, BSON_LIB),
            Ptr{Uint8}, (Ptr{Uint8}, Csize_t, Ptr{Uint8}),
            jsonCStr,
            length(jsonCStr),
            bsonError._wrap_
            )
        _wrap_ != C_NULL || error(bsonError)
        bson = new(_wrap_)
        finalizer(bson, destroy)
        return bson
    end
end
export BSON

# Private

function destroy(bson::BSON)
    ccall(
        (:bson_destroy, BSON_LIB),
        Void, (Ptr{Void},),
        bson._wrap_
        )
end
