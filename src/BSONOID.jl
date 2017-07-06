immutable BSONOID
    _wrap_::Ptr{Void}
    _ref_::Any

    BSONOID() = begin
        buffer = Array{UInt8}(12)
        ccall(
            (:bson_oid_init, libbson),
            Void, (Ptr{UInt8}, Ptr{Void}),
            buffer,
            C_NULL
            )
            r = Compat.unsafe_convert(Ptr{UInt8}, buffer)
        new(r, buffer)
    end

    BSONOID(str::AbstractString) = begin
        cstr = string(str)

        isValid = ccall(
            (:bson_oid_is_valid, libbson),
            Bool, (Ptr{UInt8}, Csize_t),
            cstr,
            length(cstr)
            )
        isValid || error("'" * str * "': not a valid BSONOID string")

        buffer = Array{UInt8}(12)
        ccall(
            (:bson_oid_init_from_string, libbson),
            Void, (Ptr{UInt8}, Ptr{UInt8}),
            buffer,
            cstr
            )
            r = Compat.unsafe_convert(Ptr{UInt8}, buffer)
        new(r, buffer)
    end

    BSONOID(_ref_::Any) = new(pointer(_ref_), _ref_)
end
export BSONOID

import Base.==
==(lhs::BSONOID, rhs::BSONOID) = ccall(
    (:bson_oid_equal, libbson),
    Bool, (Ptr{Void}, Ptr{Void}),
    lhs._wrap_, rhs._wrap_
    )
export ==

hash(oid::BSONOID, h::UInt) = hash(
    ccall(
        (:bson_oid_hash, libbson),
        UInt32, (Ptr{UInt8},),
        oid._wrap_
        ),
    h
    )
export hash

function convert(::Type{AbstractString}, oid::BSONOID)
    cstr = Array{UInt8}(25)
    ccall(
        (:bson_oid_to_string, libbson),
        Void, (Ptr{UInt8}, Ptr{UInt8}),
        oid._wrap_,
        cstr
        )
    return String(unsafe_string(Compat.unsafe_convert(Ptr{UInt8}, cstr)))
end
export convert

string(oid::BSONOID) = convert(AbstractString, oid)
export string

show(io::IO, oid::BSONOID) = print(io, "BSONOID($(convert(AbstractString, oid)))")
export show
