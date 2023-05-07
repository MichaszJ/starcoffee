# This file was generated, do not modify it. # hide
const g = 9.80665
const m = 5.0
const c = 0.25
const vt = m*g / c

@parameters t
D = Differential(t)

@variables x(t) ẋ(t) y(t) ẏ(t)