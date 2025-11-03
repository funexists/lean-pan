import LeanPan.MiniFB

def Point := Float × Float

def PolarPoint := Float × Float

def Image (c : Type) := Point → c

def Region := Image Bool

def pi : Float := 3.1415926

@[inline]
def Float.isEven (x : Float) : Bool := x.toInt64 % 2 == 0

@[inline]
def Point.abs (p : Point) : Float := (p.fst * p.fst + p.snd * p.snd).sqrt

@[inline]
def Point.fromPolar : PolarPoint → Point :=
  fun ⟨ρ, θ⟩ => ⟨ρ * θ.cos, ρ * θ.cos⟩

@[inline]
def Point.toPolar : Point → PolarPoint :=
  fun p =>
    let ρ := p.abs
    let ⟨x, y⟩ := p
    let θ := Float.atan2 y x
    ⟨ρ, θ⟩

/-- Vertical strip centered on the y-axis with half-width 0.5 -/
@[inline]
def vstrip : Region := fun p => p.fst.abs <= 0.5

/-- Checkerboard pattern based on floored coordinates -/
@[inline]
def checker : Region := fun ⟨x, y⟩ => (x.floor + y.floor).isEven

@[inline]
def polarChecker (n : Nat) : Region :=
  let sc := fun (p : PolarPoint) =>
    let ⟨ρ, θ⟩ := p
    ⟨ρ, θ * (n.toFloat / pi)⟩
  checker ∘ sc ∘ Point.toPolar

/-- Alternating concentric rings based on radial distance -/
@[inline]
def altRings : Region := fun p => p.abs.floor.isEven

/-- Sierpiński gasket -/
@[inline]
def gasket : Region :=
  fun ⟨x, y⟩ => x.floor.toInt64 ||| y.floor.toInt64 == x.floor.toInt64

@[inline]
def wavDist : Image Float := fun p => (1 + (pi * p.abs).cos) / 2

@[inline]
def zoom {c : Type} (factor : Float) (r : Image c) : Image c :=
  fun ⟨x, y⟩ =>
    let x' := x / factor
    let y' := y / factor
    r ⟨x', y'⟩

@[inline]
def translate {c : Type} (pan_x pan_y : Float) (r : Image c) : Image c :=
  fun ⟨x, y⟩ =>
    let x' := x - pan_x
    let y' := y - pan_y
    r ⟨x', y'⟩

@[inline]
def UInt8.fromIntensity (intensity : Float) : UInt8 := (intensity * (2^8 - 1).toFloat).floor.toUInt8

@[inline]
def UInt8.toIntensity (i : UInt8) : Float := i.toFloat / (2^8 - 1).toFloat

structure Color where
  r : UInt8
  g : UInt8
  b : UInt8
  a : UInt8 := 0xFF

namespace Color

@[inline]
def toUInt32 (c : Color) : UInt32 := mfb_argb c.a c.r c.g c.b

@[inline] def black : Color := mk 0x00 0x00 0x00 0xFF
@[inline] def white : Color := mk 0xFF 0xFF 0xFF 0xFF
@[inline] def red   : Color := mk 0xFF 0x00 0x00 0xFF
@[inline] def green : Color := mk 0x00 0xFF 0x00 0xFF
@[inline] def blue  : Color := mk 0x00 0x00 0xFF 0xFF
/-- Grey scale between 0 and 1, 0=white, 1=black -/
@[inline] def grey (intensity : Float) : Color :=
  let intensity := UInt8.fromIntensity (1 - intensity)
  mk intensity intensity intensity 0xFF

end Color

/-- Internpolate between colors -/
@[inline]
def lerpC (weight : Float) (startColor endColor : Color) : Color :=
 let h : UInt8 → UInt8 → UInt8 :=
   fun x₁ x₂ =>
     weight * x₁.toIntensity + (1 - weight) * x₂.toIntensity |> UInt8.fromIntensity
 {b := h startColor.b endColor.b,
  g := h startColor.g endColor.g,
  r := h startColor.r endColor.r,
  a := h startColor.a endColor.a
  : Color}

/-- Interpolate among four colors in two dimensions --/
@[inline]
def bilerpC (topLeft topRight bottomLeft bottomRight : Color) (p : Point) : Color :=
  let ⟨x, y⟩ := p
  let top := lerpC x topLeft topRight
  let bottom := lerpC x bottomLeft bottomRight
  lerpC y top bottom
