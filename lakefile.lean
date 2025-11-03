import Lake
open System Lake DSL

package «lean-pan»

lean_lib LeanPan

@[default_target]
lean_exe "lean-pan" where
  root := `Main
  moreLinkArgs := #[
    "lib/libminifb.a",
    "-framework", "Cocoa",
    "-framework", "Metal",
    "-framework", "MetalKit",
    "-framework", "QuartzCore"
  ]

lean_exe "mouse" where
  root := `MainMouse
  moreLeancArgs := #["-O3"]
  moreLinkArgs := #[
    "lib/libminifb.a",
    "-framework", "Cocoa",
    "-framework", "Metal",
    "-framework", "MetalKit",
    "-framework", "QuartzCore"
  ]

target minifb_bindings.o pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "minifb_bindings.o"
  let srcJob ← inputTextFile <| pkg.dir / "c" / "minifb_bindings.c"
  let minifbInclude := pkg.dir / "minifb" / "include"
  let weakArgs := #["-I", s!"{minifbInclude}", "-Wall", "-Wextra", "-Werror", "-O3"]
  let mut traceArgs := #["-fPIC"]
  buildLeanO oFile srcJob weakArgs traceArgs

extern_lib libminifbffi pkg := do
  let ffiO ← minifb_bindings.o.fetch
  let name := nameToStaticLib "minifblean"
  buildStaticLib (pkg.staticLibDir / name) #[ffiO]
