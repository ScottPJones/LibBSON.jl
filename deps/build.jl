using BinDeps

@BinDeps.setup

ENV["JULIA_ROOT"] = abspath(JULIA_HOME, "../../")

libbson = library_dependency(
    "libbson",
    aliases = ["libbson", "libbson-1.0"],
    runtime = false
    )

provides(Sources, {
    URI("http://github.com/mongodb/libbson/releases/download/1.0.0/libbson-1.0.0.tar.gz") => libbson
    })

provides(BuildProcess, {
    Autotools(libtarget = "libbson/libbson-1.0"*BinDeps.shlib_ext) => libbson
    })

@osx_only begin
    using Homebrew
    provides(Homebrew.HB, {"libbson" => libbson})
end

@BinDeps.install [:libbson => :libbson]
