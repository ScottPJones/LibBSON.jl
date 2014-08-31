immutable BSONOID
    _wrap_::Ptr{Void}

    BSONOID() = begin
        buffer = Array(Uint8, 12)
        ccall(
            (:bson_oid_init, BSON_LIB),
            Void, (Ptr{Uint8}, Ptr{Void}),
            buffer,
            C_NULL
            )
        new(buffer)
    end

    BSONOID(str::String) = begin
        cstr = bytestring(str)

        isValid = ccall(
            (:bson_oid_is_valid, BSON_LIB),
            Bool, (Ptr{Uint8}, Csize_t),
            cstr,
            length(cstr)
            )
        isValid || error("'" * str * "': not a valid BSONOID string")

        buffer = Array(Uint8, 12)
        ccall(
            (:bson_oid_init_from_string, BSON_LIB),
            Void, (Ptr{Uint8}, Ptr{Uint8}),
            buffer,
            cstr
            )
        new(buffer)
    end

    BSONOID(_wrap_::Ptr{Void}) = new(_wrap_)
end
export BSONOID

==(lhs::BSONOID, rhs::BSONOID) = ccall(
    (:bson_oid_equal, BSON_LIB),
    Bool, (Ptr{Void}, Ptr{Void}),
    lhs._wrap_, rhs._wrap_
    )
export ==

hash(oid::BSONOID, h::Uint) = hash(
    ccall(
        (:bson_oid_hash, BSON_LIB),
        Uint32, (Ptr{Uint8},),
        oid._wrap_
        ),
    h
    )
export hash

function convert(::Type{String}, oid::BSONOID)
    cstr = Array(Uint8, 25)
    ccall(
        (:bson_oid_to_string, BSON_LIB),
        Void, (Ptr{Uint8}, Ptr{Uint8}),
        oid._wrap_,
        cstr
        )
    return bytestring(convert(Ptr{Uint8}, cstr))
end
export convert

string(oid::BSONOID) = convert(String, oid)
export string

show(io::IO, oid::BSONOID) = print(io, "BSONOID($(convert(String, oid)))")
export show
