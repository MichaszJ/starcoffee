# This file was generated, do not modify it. # hide
model = Model(Ipopt.Optimizer)
set_silent(model)

@variables(model, begin
    Δt ≥ 0, (start = 1 / n)
    x_proj[1:n] ≥ 0
    y_proj[1:n] ≥ 0

    0 ≤ vx_proj[1:n] ≤ 100
    vy_proj[1:n] ≤ 100
end)