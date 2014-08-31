type BSONError
    _wrap_::Vector{Uint8}

    function BSONError()
        return new(Array(Uint8, 512))
    end
end
export BSONError

function error(bsonError::BSONError)
    uint32s = reinterpret(Uint32, bsonError._wrap_)
    domain = uint32s[1]
    code = uint32s[2]
    message = bytestring(bsonError._wrap_[9:end])
    error("libBSON (domain $domain, code $code): $message")
end
export error
