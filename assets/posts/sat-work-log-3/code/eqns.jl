# This file was generated, do not modify it. # hide
three_body_equations = [
    r₁₂ ~ sqrt((x₂ - x₁)^2 + (y₂ - y₁)^2 + (z₂ - z₁)^2),
    r₁₃ ~ sqrt((x₃ - x₁)^2 + (y₃ - y₁)^2 + (z₃ - z₁)^2),
    r₂₃ ~ sqrt((x₃ - x₂)^2 + (y₃ - y₂)^2 + (z₃ - z₂)^2),

    D(x₁) ~ ẋ₁,
    D(y₁) ~ ẏ₁,
    D(z₁) ~ ż₁,
    D(ẋ₁) ~ G*m₂*(x₂ - x₁)/r₁₂^3 + G*m₃*(x₃ - x₁)/r₁₃^3,
    D(ẏ₁) ~ G*m₂*(y₂ - y₁)/r₁₂^3 + G*m₃*(y₃ - y₁)/r₁₃^3,
    D(ż₁) ~ G*m₂*(z₂ - z₁)/r₁₂^3 + G*m₃*(z₃ - z₁)/r₁₃^3,

    D(x₂) ~ ẋ₂,
    D(y₂) ~ ẏ₂,
    D(z₂) ~ ż₂,
    D(ẋ₂) ~ G*m₁*(x₁ - x₂)/r₁₂^3 + G*m₃*(x₃ - x₂)/r₂₃^3,
    D(ẏ₂) ~ G*m₁*(y₁ - y₂)/r₁₂^3 + G*m₃*(y₃ - y₂)/r₂₃^3,
    D(ż₂) ~ G*m₁*(z₁ - z₂)/r₁₂^3 + G*m₃*(z₃ - z₂)/r₂₃^3,

    D(x₃) ~ ẋ₃,
    D(y₃) ~ ẏ₃,
    D(z₃) ~ ż₃,
    D(ẋ₃) ~ G*m₁*(x₁ - x₃)/r₁₃^3 + G*m₂*(x₂ - x₃)/r₂₃^3,
    D(ẏ₃) ~ G*m₁*(y₁ - y₃)/r₁₃^3 + G*m₂*(y₂ - y₃)/r₂₃^3,
    D(ż₃) ~ G*m₁*(z₁ - z₃)/r₁₃^3 + G*m₂*(z₂ - z₃)/r₂₃^3,
]

diffeq_three_body_system = ODESystem(
    three_body_equations,
    t,
    name=:three_body_system
) |> structural_simplify