type BSONError
    _wrap_::Vector{Uint8}

    function BSONError()
        return new(Array(Uint8, 512))
    end
end
export BSONError

const domainDescs = {1 => "JSON", 2 => "READER"}
const errorDescs = {
    1 => {
        1 => "READ_CORRUPT_JS",
        2 => "READ_INVALID_PARAM",
        3 => "READ_CB_FAILURE",
        },
    2 => {
        1 => "BADFD",
        },
    }

function error(bsonError::BSONError)
    uint32s = reinterpret(Uint32, bsonError._wrap_)
    domain = uint32s[1]
    code = uint32s[2]
    message = bytestring(bsonError._wrap_[9:end])
    error("libBSON:$(domainDescs[domain]):$(errorDescs[domain][code]): $message")
end
export error
