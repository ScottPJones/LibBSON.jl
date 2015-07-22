module LibBSON

using Compat

include( "../deps/deps.jl")

LIBBSON_VERSION = VersionNumber(
    ccall((:bson_get_major_version, libbson), Cint, ()),
    ccall((:bson_get_minor_version, libbson), Cint, ()),
    ccall((:bson_get_micro_version, libbson), Cint, ()),
    )
export LIBBSON_VERSION

import Base.hash,
    Base.convert,
    Base.show,
    Base.error,
    Base.start,
    Base.next,
    Base.done,
    Base.string,
    Base.length

typealias Obj @compat Dict{Any,Any}

include("BSONOID.jl")
include("BSONError.jl")
include("BSONObject.jl")
include("BSONArray.jl")
include("BSONType.jl")
include("BSONIter.jl")

end
