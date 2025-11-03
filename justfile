minifb_build_path := join(justfile_directory(), "minifb", "build")
static_lib_path := join(justfile_directory(), "lib")

build_minifb:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f "{{static_lib_path}}/libminifb.a" ]; then
        mkdir -p {{static_lib_path}}
        mkdir -p {{minifb_build_path}}
        cd {{minifb_build_path}}
        cmake .. -DMINIFB_BUILD_EXAMPLES=FALSE
        make -j8
        cp {{minifb_build_path}}/libminifb.a {{static_lib_path}}
    fi

clean_minifb:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -d "{{minifb_build_path}}" ]; then
        cd {{minifb_build_path}}
        make clean
        rm -rf {{minifb_build_path}}
    fi

    if [ -f "{{static_lib_path}}/libminifb.a" ]; then
        rm {{static_lib_path}}/libminifb.a
    fi

# set to the C compiler used to build native libraries (e.g raylib CC, and lake LEAN_CC)
native_compiler := if os() == "macos" { "/usr/bin/clang" } else { "clang" }

# The path to the GMP library root
#
# On macOS use `brew install gmp` to install it
gmp_prefix := if os() == "macos" { shell("brew --prefix gmp") } else { "" }

# The path to libuv root
#
# On macOS use `brew install libuv` to install it
libuv_prefix := if os() == "macos" { shell("brew --prefix libuv") } else { "" }

# The value of LIBRARY_PATH used when running `just build`. This is passed to
# the C compiler when lake builds native objects.
library_path := if gmp_prefix == "" { "" } else if libuv_prefix == "" { "" } else {gmp_prefix + "/lib:" + libuv_prefix + "/lib"}

clean_lake:
    lake clean

clean: clean_minifb clean_lake

# build both the raylib library and the Lake project
build: build_minifb
    LIBRARY_PATH={{library_path}} LEAN_CC={{native_compiler}} lake build

run: build
    LIBRARY_PATH={{library_path}} LEAN_CC={{native_compiler}} lake exe lean-pan

run-mouse: build
    LIBRARY_PATH={{library_path}} LEAN_CC={{native_compiler}} lake exe mouse
