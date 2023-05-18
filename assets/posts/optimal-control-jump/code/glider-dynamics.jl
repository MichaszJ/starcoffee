# This file was generated, do not modify it. # hide
for j in 2:n_glider
    @NLconstraint(glider_model, x[j] == x[j-1] + 0.5*Δt*(vx[j] + vx[j-1]))
    @NLconstraint(glider_model, y[j] == y[j-1] + 0.5*Δt*(vy[j] + vy[j-1]))
    @NLconstraint(glider_model,
        vx[j] == vx[j-1] + 0.5*Δt*(
            (1/m)*(-L[j] * sin_η[j] - D[j] * cos_η[j]) +
            (1/m)*(-L[j-1] * sin_η[j-1] - D[j-1] * cos_η[j-1])
        )
    )
    @NLconstraint(glider_model,
        vy[j] == vy[j-1] + 0.5*Δt*(
            (1/m)*(L[j] * cos_η[j] - D[j] * sin_η[j] - m*g) +
            (1/m)*(L[j-1] * cos_η[j-1] - D[j-1] * sin_η[j-1] - m*g)
        )
    )
end