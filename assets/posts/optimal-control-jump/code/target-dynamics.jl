# This file was generated, do not modify it. # hide
for j ∈ 2:n
    @NLconstraint(model,
        x_proj[j] == x_proj[j-1] + 0.5*Δt*(vx_proj[j] + vx_proj[j-1])
    )
    @NLconstraint(model,
        y_proj[j] == y_proj[j-1] + 0.5*Δt*(vy_proj[j] + vy_proj[j-1])
    )

    @NLconstraint(model,
        vx_proj[j] == vx_proj[j-1] + 0.5*Δt*(ax[j] + ax[j-1])
    )
    @NLconstraint(model,
        vy_proj[j] == vy_proj[j-1] + 0.5*Δt*(ay[j] + ay[j-1])
    )
end