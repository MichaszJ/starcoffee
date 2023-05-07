# This file was generated, do not modify it. # hide
target2 = [180, 20]

sol12 = simulate_projectile2(ẋ1, ẏ1)
sol22 = simulate_projectile2(ẋ2, ẏ2)

fig4 = Figure(resolution=(1000,300))
ax4 = Axis(fig4[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax4, [target2[1]], [target2[2]], label="Target")

lines!(ax4, interp_sol(sol12, [x,y], times)..., label="Trajectory 1")
lines!(ax4, interp_sol(sol22, [x,y], times)..., label="Trajectory 2")

axislegend(ax4, position=:lt)
save("assets/posts/direct-shooting-with-approx/code/guess2.svg", fig4) #hide