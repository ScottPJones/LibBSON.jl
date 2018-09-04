
struct BSONOID
    _wrap_::VoidPtr
    _ref_::Any

    function BSONOID()
        buffer = alloc_buf(12)
        ccall((:bson_oid_init, libbson), Cvoid, (BytePtr, VoidPtr), buffer, C_NULL)
        r = Base.unsafe_convert(BytePtr, buffer)
        new(r, buffer)
    end

    function BSONOID(str::AbstractString)
        cstr = string(str)

        isValid = ccall((:bson_oid_is_valid, libbson), Bool, (BytePtr, Csize_t),
                        cstr, length(cstr))
        isValid || error("'" * str * "': not a valid BSONOID string")

        buffer = alloc_buf(12)
        ccall((:bson_oid_init_from_string, libbson), Cvoid, (BytePtr, BytePtr), buffer, cstr)
        r = Base.unsafe_convert(BytePtr, buffer)
        new(r, buffer)
    end

    BSONOID(_ref_::Any) = new(pointer(_ref_), _ref_)
end

export BSONOID

Base.:(==)(lhs::BSONOID, rhs::BSONOID) =
    ccall((:bson_oid_equal, libbson), Bool, (VoidPtr, VoidPtr), lhs._wrap_, rhs._wrap_)

Base.hash(oid::BSONOID, h::UInt) =
    hash(ccall((:bson_oid_hash, libbson), UInt32, (BytePtr,), oid._wrap_), h)

function Base.convert(::Type{AbstractString}, oid::BSONOID)
    cstr = alloc_buf(25)
    ccall((:bson_oid_to_string, libbson), Cvoid, (BytePtr, BytePtr), oid._wrap_, cstr)
    String(unsafe_string(Base.unsafe_convert(BytePtr, cstr)))
end

Base.string(oid::BSONOID) = convert(AbstractString, oid)

Base.show(io::IO, oid::BSONOID) = print(io, "BSONOID($(convert(AbstractString, oid)))")
