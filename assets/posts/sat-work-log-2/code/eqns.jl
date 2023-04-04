# This file was generated, do not modify it. # hide
two_body_equations = [
    r ~ sqrt((x₂ - x₁)^2 + (y₂ - y₁)^2 + (z₂ - z₁)^2),

    D(x₁) ~ ẋ₁,
    D(y₁) ~ ẏ₁,
    D(z₁) ~ ż₁,

    D(ẋ₁) ~ G*m₂*(x₂ - x₁)/r^3,
    D(ẏ₁) ~ G*m₂*(y₂ - y₁)/r^3,
    D(ż₁) ~ G*m₂*(z₂ - z₁)/r^3,

    D(x₂) ~ ẋ₂,
    D(y₂) ~ ẏ₂,
    D(z₂) ~ ż₂,

    D(ẋ₂) ~ G*m₁*(x₁ - x₂)/r^3,
    D(ẏ₂) ~ G*m₁*(y₁ - y₂)/r^3,
    D(ż₂) ~ G*m₁*(z₁ - z₂)/r^3,
]