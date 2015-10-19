type BSONError
    _wrap_::Vector{UInt8}

    function BSONError()
        return new(Array(UInt8, 512))
    end
end
export BSONError

const domainDescs = @compat Dict{Int64,AbstractString}(1 => "JSON", 2 => "READER")
const errorDescs = @compat Dict{Int64,Any}(1 => (@compat Dict{Int64,AbstractString}(
        1 => "READ_CORRUPT_JS",
        2 => "READ_INVALID_PARAM",
        3 => "READ_CB_FAILURE"
    )), 2 => @compat Dict{Int64,AbstractString}(1 => "BADFD"))

convert(::Type{AbstractString}, bsonError::BSONError) = begin
    uint32s = reinterpret(UInt32, bsonError._wrap_)
    domain = uint32s[1]
    code = uint32s[2]
    return bytestring(convert(Ptr{UInt8}, bsonError._wrap_[9:end]))
end
export convert

string(bsonError::BSONError) = bytestring(bsonError._wrap_)
export string

error(bsonError::BSONError) = error(string(bsonError))
export error
