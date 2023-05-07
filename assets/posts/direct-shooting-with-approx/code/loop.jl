# This file was generated, do not modify it. # hide
fig2 = Figure(resolution=(1000,300))
    ax2 = Axis(fig2[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

    scatter!(ax2, [target[1]], [target[2]], label="Target")

    lines!(ax2, interp_sol(sol1, [x,y], times)..., label="Trajectory 1")
    lines!(ax2, interp_sol(sol2, [x,y], times)..., label="Trajectory 2")

    errors = [
    abs(sol1[x, end] - target[1]),
    abs(sol2[x, end] - target[1])
]

ẋ2_sim = copy(ẋ2)
ẏ2_sim = copy(ẏ2)

n_iters = 10

for i in 1:n_iters
    sol3 = simulate_projectile(ẋ3_sim, ẏ3_sim)

    global F1 = copy(F2)
    global F2 = [sol3[x, end], sol3[y, end]] .- target

    global dF = [
        (F2[1] - F1[1])/(ẋ3_sim - ẋ2_sim) (F2[1] - F1[1])/(ẏ3_sim - ẏ2_sim)
        0 0
    ]

    global ẋ2_sim = copy(ẋ3_sim)
    global ẏ2_sim = copy(ẏ3_sim)

    u̇ = [ẋ2_sim, ẏ2_sim] .- pinv(dF)*F2

    global ẋ3_sim = u̇[1]
    global ẏ3_sim = u̇[2]

    if i < n_iters
        lines!(
            ax2, interp_sol(sol3, [x,y], times)...,
            linestyle=:dash, color = (:red, 0.2)
        )
    else
        lines!(
            ax2, interp_sol(sol3, [x,y], times)...,
            color=:red, label="Trajectory $(n_iters+2)"
        )
    end

    push!(errors, abs(sol3[x, end] - target[1]))
end

axislegend(ax2, position=:lt)
fig2
save("assets/posts/direct-shooting-with-approx/code/results.svg", fig2) #hide