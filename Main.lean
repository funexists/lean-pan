import LeanPan

-- This example has no state so we use unit
abbrev State := Unit

@[export image_frame]
unsafe def imageFrame (_state : Unit) (x y : Float) : UInt32 :=
  if checker ⟨x, y⟩ then Color.white.toUInt32 else Color.black.toUInt32

@[extern "render"]
opaque render : (state : @& State) → IO Bool

def main : IO Unit := do
  initSquareWindow (dimension := 800) (scale := 10) (title := "Hello World")

  while not (← windowShouldClose) do
    if not (← render .unit) then
      return
