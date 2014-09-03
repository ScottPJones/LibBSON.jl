using BinDeps

@BinDeps.setup

libbson = library_dependency(
    "libbson",
    aliases = ["libbson", "libbson-1.0"]
    )

provides(Sources, {
    URI("http://github.com/mongodb/libbson/releases/download/1.0.0/libbson-1.0.0.tar.gz") => libbson
    })

provides(
    BuildProcess,
    Autotools(libtarget = "libbson-1.0.la"),
    libbson,
    os = :Unix
    )
            
@osx_only begin
    using Homebrew
    provides(Homebrew.HB, {"libbson" => libbson})
end

@BinDeps.install [:libbson => :libbson]
