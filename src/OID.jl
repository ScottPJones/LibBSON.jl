immutable OID
    _wrap_::Vector{Uint8}

    function OID()
        oid = new(Array(Uint8, 12))
        ccall(
            (:bson_oid_init, BSON_LIB),
            Void, (Ptr{Uint8}, Ptr{Void}),
            oid._wrap_,
            C_NULL
            )
        return oid           
    end

    function OID(str::String)
        cstr = bytestring(str)

        isValid = ccall(
            (:bson_oid_is_valid, BSON_LIB),
            Bool, (Ptr{Uint8}, Csize_t),
            cstr,
            length(cstr)
            )
        isValid || error("'" * str * "': not a valid BSON.OID string")

        oid = new(Array(Uint8, 12))
        ccall(
            (:bson_oid_init_from_string, BSON_LIB),
            Void, (Ptr{Uint8}, Ptr{Uint8}),
            oid._wrap_,
            cstr
            )
        return oid           
    end
end
export OID

==(lhs::OID, rhs::OID) = (lhs._wrap_ == rhs._wrap_)
export ==

function convert(::Type{String}, oid::OID)
    cstr = Array(Uint8, 25)
    ccall(
        (:bson_oid_to_string, BSON_LIB),
        Void, (Ptr{Uint8}, Ptr{Uint8}),
        oid._wrap_,
        cstr
        )
    return bytestring(cstr)
end
export convert

import Base.hash, Base.convert
function hash(oid::OID, h::Uint)
    oidHash = ccall(
        (:bson_oid_hash, BSON_LIB),
        Uint32, (Ptr{Uint8},),
        oid._wrap_
        )
    return hash(oidHash, h)
end
export hash

import Base.show
show(io::IO, oid::OID) = print(io, "BSON.OID($(convert(String, oid)))")
export show
