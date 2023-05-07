# This file was generated, do not modify it. # hide
fig5 = Figure(resolution=(1000,300))
ax5 = Axis(fig5[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax5, [target2[1]], [target2[2]], label="Target")

lines!(ax5, interp_sol(sol12, [x,y], times)..., label="Trajectory 1")
lines!(ax5, interp_sol(sol22, [x,y], times)..., label="Trajectory 2")

ẋ2_sim2 = copy(ẋ2)
ẏ2_sim2 = copy(ẏ2)

errors2 = [
    sqrt((sol12[x, end] - target2[1])^2 + (sol12[y, end] - target2[2])^2),
    sqrt((sol22[x, end] - target2[1])^2 + (sol22[y, end] - target2[2])^2)
]

n_iters2 = 10

for i in 1:n_iters2
    sol32 = simulate_projectile2(ẋ3_sim2, ẏ3_sim2)

    global F12 = copy(F22)
    global F22 = [sol32[x, end], sol32[y, end]] .- target2

    global dF2 = [
        (F22[1] - F12[1])/(ẋ3_sim2 - ẋ2_sim2) (F22[1] - F12[1])/(ẏ3_sim2 - ẏ2_sim2)
        (F22[2] - F12[2])/(ẋ3_sim2 - ẋ2_sim2) (F22[2] - F12[2])/(ẏ3_sim2 - ẏ2_sim2)
    ]

    global ẋ2_sim2 = copy(ẋ3_sim2)
    global ẏ2_sim2 = copy(ẏ3_sim2)

    u̇ = [ẋ2_sim2, ẏ2_sim2] .- pinv(dF2)*F22

    global ẋ3_sim2 = u̇[1]
    global ẏ3_sim2 = u̇[2]

    if i < n_iters
        lines!(
            ax5, interp_sol(sol32, [x,y], times)...,
            linestyle=:dash, color = (:red, 0.2)
        )
    else
        lines!(
            ax5, interp_sol(sol32, [x,y], times)...,
            color=:red, label="Trajectory $(n_iters+2)"
        )
    end
    push!(errors2, sqrt((sol32[x, end] - target2[1])^2 + (sol32[y, end] - target2[2])^2))
end

axislegend(ax5, position=:lt)
fig5
save("assets/posts/direct-shooting-with-approx/code/loop2.svg", fig5) #hide