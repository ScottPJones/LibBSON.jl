
struct BSONError
    _wrap_::Vector{UInt8}

    BSONError() = new(alloc_buf(512))
end

export BSONError

const domainDescs = Dict{Int64,AbstractString}(1 => "JSON", 2 => "READER")
const errorDescs = Dict{Int64,Any}(1 => (Dict{Int64,AbstractString}(
        1 => "READ_CORRUPT_JS",
        2 => "READ_INVALID_PARAM",
        3 => "READ_CB_FAILURE"
    )), 2 => Dict{Int64,AbstractString}(1 => "BADFD"))

function Base.convert(::Type{String}, bsonError::BSONError)
    uint32s = reinterpret(UInt32, bsonError._wrap_)
    domain = uint32s[1]
    code = uint32s[2]
    return String(bsonError._wrap_[9:end])
end

Base.string(bsonError::BSONError) = String(bsonError._wrap_)

Base.error(bsonError::BSONError) = error(string(bsonError))
