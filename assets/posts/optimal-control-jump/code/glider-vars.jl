# This file was generated, do not modify it. # hide
@variables(glider_model, begin
    # Time step
    Δt ≥ 0, (start = 1 / n_glider)

    # state variables
    x[1:n_glider] ≥ 0
    vx[1:n_glider] ≥ 0
    y[1:n_glider] ≥ 0
    vy[1:n_glider]

    # control variable
    0 ≤ C_L[1:n_glider] ≤ 1.4
end)