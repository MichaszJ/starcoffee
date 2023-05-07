# This file was generated, do not modify it. # hide
sys = ODESystem(
    [
        D(x) ~ ẋ,
        D(ẋ) ~ -(g/vt)*ẋ,
        D(y) ~ ẏ,
        D(ẏ) ~ -g - (g/vt)*ẏ
    ],
    t,
    name = :proj_drag_system
)