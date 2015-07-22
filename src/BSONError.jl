type BSONError
    _wrap_::Vector{Uint8}

    function BSONError()
        return new(Array(Uint8, 512))
    end
end
export BSONError

const domainDescs = @compat Dict{Int64,String}(1 => "JSON", 2 => "READER")
const errorDescs = @compat Dict{Int64,Any}(1 => (@compat Dict{Int64,String}(
        1 => "READ_CORRUPT_JS",
        2 => "READ_INVALID_PARAM",
        3 => "READ_CB_FAILURE"
    )), 2 => @compat Dict{Int64,String}(1 => "BADFD"))

convert(::Type{String}, bsonError::BSONError) = begin
    uint32s = reinterpret(Uint32, bsonError._wrap_)
    domain = uint32s[1]
    code = uint32s[2]
    return bytestring(convert(Ptr{Uint8}, bsonError._wrap_[9:end]))
end
export convert

string(bsonError::BSONError) = convert(String, bsonError)
export string

error(bsonError::BSONError) = error(string(bsonError))
export error
