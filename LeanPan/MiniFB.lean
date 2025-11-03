@[extern "initWindow"]
opaque initWindow : (width height x_scale y_scale : Nat) → (title : @& String) → IO Unit

def initSquareWindow (dimension scale : Nat) (title: String) : IO Unit :=
  initWindow dimension dimension scale scale title

@[extern "windowShouldClose"]
opaque windowShouldClose : IO Bool

@[extern "get_time"]
opaque getTime : IO Float

@[extern "get_mouse_pos_x"]
opaque getMouseX : IO Float

@[extern "get_mouse_pos_y"]
opaque getMouseY : IO Float

@[extern "is_key_down"]
opaque isKeyDown : (key : UInt32) → IO Bool

@[extern "mfb_argb"]
opaque mfb_argb (a r g b : UInt8) : UInt32
