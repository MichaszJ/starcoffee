# This file was generated, do not modify it. # hide
K_m = 4.5
T_m = 0.85

@named prm = PseudorateModulator(time_constant=T_m, filter_gain=K_m, U_on=U_on, U_off=U_off)

prm_sol = simulate_system(prm; tspan=tspan, adaptive=false, dt=0.005)

interp_prm = prm_sol(times)

fig5 = Figure()
ax51 = Axis(fig5[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax51, times, rad2deg.(interp_prm[plant.ϕ]))
hlines!(ax51, [rad2deg(setpoint)], linestyle=:dash)

fig5
save("assets/posts/sac-thrusters/code/prm-sim.svg", fig5) #hide