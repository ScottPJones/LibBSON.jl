__precompile__(true)

module LibBSON

@static if VERSION < v"0.7-"
    const Nothing = Void
    const Cvoid   = Void
    const AbstractDict = Associative
    const unsafe_copyto! = unsafe_copy!
    finalizer(f::Function, o) = Base.finalizer(o, f)
end
@static VERSION < v"0.7-" ? (using Base.Dates) : (using Dates)
alloc_buf(n) = @static VERSION < v"0.7-" ? Vector{UInt8}(n) : Vector{UInt8}(undef, n)

const VoidPtr = Ptr{Cvoid}
const BytePtr = Ptr{UInt8}

@noinline bson_ovf() = error("libBSON: overflow")

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
