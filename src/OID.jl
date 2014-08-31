export OID

type OID
    _wrap_::Vector{Cchar}

    function OID()
        oid = new(Array(Cchar, 12))
        ccall(
            (:bson_oid_init, BSON_LIB),
            Void, (Ptr{Cchar}, Ptr{Void}),
            oid._wrap_,
            C_NULL
            )
        return oid           
    end
end
