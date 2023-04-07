# This file was generated, do not modify it. # hide
earth_moon_cr_three_body_equations = [
    r₁ ~ sqrt((x + π₂*r₁₂_val)^2 + y^2 + z^2),
    r₂ ~ sqrt((x - π₁*r₁₂_val)^2 + y^2 + z^2),

    Di(x) ~ ẋ,
    Di(y) ~ ẏ,
    Di(z) ~ ż,

    Di(ẋ) ~ 2*Ω*ẏ + x*Ω^2 - (x + π₂*r₁₂_val)*μ₁/r₁^3 - (x - π₁*r₁₂_val)*μ₂/r₂^3,
    Di(ẏ) ~ y*Ω^2 - 2*Ω*ẋ - y*μ₁/r₁^3 - y*μ₂/r₂^3,
    Di(ż) ~ -z*μ₁/r₁^3 - z*μ₂/r₂^3,
]

earth_moon_cr_three_body_system = ODESystem(
    earth_moon_cr_three_body_equations,
    ti,
    name=:earth_moon_cr_three_body_system
) |> structural_simplify