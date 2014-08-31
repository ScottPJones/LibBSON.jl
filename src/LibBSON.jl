module LibBSON

const BSON_LIB = "libbson-1.0"

LIBBSON_VERSION = VersionNumber(
    ccall((:bson_get_major_version, BSON_LIB), Cint, ()),
    ccall((:bson_get_minor_version, BSON_LIB), Cint, ()),
    ccall((:bson_get_micro_version, BSON_LIB), Cint, ()),
    )
export LIBBSON_VERSION

import Base.hash, Base.convert, Base.show, Base.error

include("BSONOID.jl")
include("BSONError.jl")
include("BSON.jl")

end
