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
  let i : Image Color := bilerpC Color.black Color.red Color.blue Color.white
  (translate (-0.5) (-0.5) i) ⟨x, y⟩ |>.toUInt32

@[inline, export image_frame]
def imageFrame (_state : Unit) (x y : Float) : UInt32 :=
  bilerpExample x y

@[extern "render"]
opaque render : (state : @& State) → IO Bool

def main : IO Unit := do
  initSquareWindow (dimension := 800) (scale := 1) (title := "Hello World")

  while not (← windowShouldClose) do
    if not (← render .unit) then
      return
