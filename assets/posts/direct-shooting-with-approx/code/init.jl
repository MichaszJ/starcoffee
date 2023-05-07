# This file was generated, do not modify it. # hide
target = [200, 0]

ẋ1 = 40.0
ẋ2 = 41.0

ẏ1 = 25.0
ẏ2 = 26.0

function simulate_projectile(ẋ0, ẏ0; tspan=[0.0, 15.0])
    u0 = [
        x => 0.0,
        ẋ => ẋ0,
        y => 0.0,
        ẏ => ẏ0
    ]

    prob = ODEProblem(sys, u0, tspan, jac=true)

    return solve(prob, Tsit5(), callback=ground_cb)
end

sol1 = simulate_projectile(ẋ1, ẏ1)
sol2 = simulate_projectile(ẋ2, ẏ2)

function interp_sol(
    solution::ODESolution,
    vars::Vector{Num},
    times::Union{StepRangeLen, Vector}
)

    sol_interp = solution(times)
    return [sol_interp[var] for var in vars]
end

fig1 = Figure(resolution=(1000,300))
ax1 = Axis(fig1[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax1, [target[1]], [target[2]], label="Target")

times=0.0:0.1:15.0
lines!(ax1, interp_sol(sol1, [x,y], times)..., label="Trajectory 1")
lines!(ax1, interp_sol(sol2, [x,y], times)..., label="Trajectory 2")

axislegend(ax1, position=:lt)
save("assets/posts/direct-shooting-with-approx/code/init.svg", fig1) #hide