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
