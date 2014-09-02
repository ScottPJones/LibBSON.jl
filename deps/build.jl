using BinDeps

@BinDeps.setup

ENV["JULIA_ROOT"] = abspath(JULIA_HOME, "../../")

libbson = library_dependency("libbson-1.0")

# TODO: add other providers with correct names
provides(AptGet, {"libmongo-client-dev" => libbson})

@osx_only begin
    using Homebrew
    provides(Homebrew.HB, {"libbson" => libbson})
end

@BinDeps.install [:libbson => :libbson]
