Model three_body_system with 18 equations
States (18):
  x₁(t)
  ẋ₁(t)
  y₁(t)
  ẏ₁(t)
  z₁(t)
  ż₁(t)
  x₂(t)
  ẋ₂(t)
  y₂(t)
  ẏ₂(t)
  z₂(t)
  ż₂(t)
  x₃(t)
  ẋ₃(t)
  y₃(t)
  ẏ₃(t)
  z₃(t)
  ż₃(t)
Parameters (4):
  G
  m₃
  m₂
  m₁
Incidence matrix:18×45 SparseArrays.SparseMatrixCSC{Symbolics.Num, Int64} with 108 stored entries:
⎡⡊⡢⡂⡂⡂⡂⡂⡂⡂⠡⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⠀⎤
⎢⡂⡂⡊⡢⡂⡂⡂⡂⡂⠀⠡⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⠀⎥
⎢⡂⡂⡂⡂⡊⡢⡂⡂⡂⠀⠀⠡⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⠀⎥
⎢⡂⡂⡂⡂⡂⡂⡊⡢⡂⠀⠀⠀⠡⠀⠀⠀⠀⠀⠀⠀⠀⢂⠀⎥
⎣⠂⠂⠂⠂⠂⠂⠂⠂⠊⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠂⎦