import LeanPan

structure State where
  pan_x : Float := 0.0
  pan_y : Float := 0.0

@[inline, export image_frame]
def imageFrame (s : @& State) (x y : Float) : UInt32 :=
  let base : Region := altRings
  let r : Region := translate s.pan_x s.pan_y base
  if r ⟨x, y⟩ then
    Color.toUInt32 Color.white
  else
    Color.toUInt32 Color.blue

@[extern "render"]
opaque render : (state : @& State) → IO Bool

def main : IO Unit := do

    let dimension := 1000
    let scale := 10
    initSquareWindow dimension scale "Mouse"

    let mut state : State := {}
    let mut frameCount := 0
    let mut elapsed : Float := 0

    while not (← windowShouldClose) do

      let pan_x ← getMouseX
      let pan_y ← getMouseY
      state := {pan_x, pan_y}
      if not (← render state) then
        return

      frameCount := frameCount + 1
      elapsed := elapsed + (← getTime)
      if frameCount % 60 == 0 && elapsed > 0 then do
        let fps := frameCount.toFloat / elapsed
        IO.println s!"Frame {frameCount}: {fps} FPS (avg over {elapsed}s)"
        frameCount := 0
        elapsed := 0
