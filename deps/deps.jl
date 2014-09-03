macro checked_lib(libname, path)
        (dlopen_e(path) == C_NULL) && error("Unable to load \n\n$libname ($path)\n\nPlease re-run Pkg.build(package), and restart Julia.")
        quote const $(esc(libname)) = $path end
    end
@checked_lib libbson "/home/pzion/.julia/v0.3/LibBSON/deps/usr/lib/libbson-1.0.so"

