# This file was generated, do not modify it. # hide
prob = ODEProblem(sys, [], (0, 5*60.0), [])
sol = solve(prob, Tsit5())

fig1 = Figure()
ax1 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (rad)")

lines!(ax1, 0:1:5*60, sol(0:1:5*60)[inertia.phi])

fig1
save("assets/posts/acausal-sadc-modelling/code/init-sol.svg", fig1) #hide