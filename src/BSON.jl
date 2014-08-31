module BSON

const BSON_LIB = "libbson-1.0"

LIBBSON_VERSION = (
    ccall((:bson_get_major_version, BSON_LIB), Cint, ()),
    ccall((:bson_get_minor_version, BSON_LIB), Cint, ()),
    ccall((:bson_get_micro_version, BSON_LIB), Cint, ()),
    )
export LIBBSON_VERSION

include("OID.jl")

end
