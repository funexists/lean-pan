import LeanPan

-- This example has no state so we use unit
abbrev State := Unit

@[inline]
def polarCheckerExample (x y : Float) : UInt32 :=
  if polarChecker 10 ⟨x, y⟩ then Color.white.toUInt32 else Color.black.toUInt32

@[inline]
def wavDistExample (x y : Float) : UInt32 :=
  Color.grey (intensity := wavDist ⟨x, y⟩) |>.toUInt32

@[inline]
def bilerpExample (x y : Float) : UInt32 :=
  -- Assumes that the window scale is set to 1
  let i : Image Color := bilerpC_simd Color.black Color.red Color.blue Color.white
  (translate (-0.5) (-0.5) i) ⟨x, y⟩ |>.toUInt32

@[inline]
def bilerpExample_unbox (x y : Float) : UInt32 :=
  -- Assumes that the window scale is set to 1
  let i : Image ColorUnbox := bilerpC_simd_unbox .black .red .blue .white
  ((translate (-0.5) (-0.5) i) ⟨x, y⟩).argb

@[inline, export image_frame]
def imageFrame (_state : Unit) (x y : Float) : UInt32 :=
  bilerpExample x y

@[extern "render"]
opaque render : (state : @& State) → IO Bool

def main : IO Unit := do
  initSquareWindow (dimension := 800) (scale := 1) (title := "Hello World")

  let mut frameCount := 0
  let mut elapsed : Float := 0

  while not (← windowShouldClose) do
    if not (← render .unit) then
      return

    frameCount := frameCount + 1
    elapsed := elapsed + (← getTime)
    if frameCount % 2 == 0 && elapsed > 0 then do
      let fps := frameCount.toFloat / elapsed
      IO.println s!"Frame {frameCount}: {fps} FPS (avg over {elapsed}s)"
      frameCount := 0
      elapsed := 0
