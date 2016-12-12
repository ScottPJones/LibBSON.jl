using BinDeps

@BinDeps.setup

libbson = library_dependency(
    "libbson",
    aliases = ["libbson", "libbson-1.0"]
    )

provides(Sources, Dict(
    URI("http://github.com/mongodb/libbson/releases/download/1.0.0/libbson-1.0.0.tar.gz") => libbson
    ))

provides(
    BuildProcess,
    Autotools(libtarget = "libbson-1.0.la"),
    libbson,
    os = :Unix
    )
            
@static if is_apple()
    using Homebrew
    Homebrew.rm("libbson")
    provides(Homebrew.HB, "mongo-c-driver", libbson, os = :Darwin)
end

@BinDeps.install Dict(:libbson => :libbson)
