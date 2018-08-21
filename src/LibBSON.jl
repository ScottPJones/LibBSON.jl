
__precompile__(true)
module LibBSON

const deps_script = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(deps_script)
    error("LibBSON.jl is not installed properly, run Pkg.build(\"LibBSON\") and restart Julia.")
end
include(deps_script)
check_deps()

LIBBSON_VERSION = VersionNumber(
    ccall((:bson_get_major_version, libbson), Cint, ()),
    ccall((:bson_get_minor_version, libbson), Cint, ()),
    ccall((:bson_get_micro_version, libbson), Cint, ()),
)

export LIBBSON_VERSION

include("BSONOID.jl")
include("BSONError.jl")
include("BSONObject.jl")
include("BSONArray.jl")
include("BSONType.jl")
include("BSONIter.jl")

end
