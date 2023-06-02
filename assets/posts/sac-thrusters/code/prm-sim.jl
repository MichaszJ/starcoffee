# This file was generated, do not modify it. # hide
K_m = 4.5
T_m = 0.85

@named prm = PseudorateModulator(time_constant=T_m, filter_gain=K_m, U_on=U_on, U_off=U_off, torque=F*L)

prm_sol = simulate_system(prm; tspan=tspan, adaptive=false, dt=0.005)

@named prm_alt = PseudorateModulatorAlt(time_constant=T_m, U_on=U_on, U_off=U_off, torque=F*L)
prm_alt_sol = simulate_system(prm_alt; tspan=tspan, adaptive=false, dt=0.005)

interp_prm = prm_sol(times)
interp_prm_alt = prm_alt_sol(times)

fig5 = Figure()
ax51 = Axis(fig5[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax51, times, rad2deg.(interp_prm[plant.ϕ]), label=L"K_m = %$(K_m)")
lines!(ax51, times, rad2deg.(interp_prm_alt[plant.ϕ]), label=L"K_m = 1")

hlines!(ax51, [rad2deg(setpoint)], linestyle=:dash)

axislegend(ax51)

fig5
save("assets/posts/sac-thrusters/code/prm-sim.svg", fig5) #hide