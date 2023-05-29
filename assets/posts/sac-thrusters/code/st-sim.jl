# This file was generated, do not modify it. # hide
U_on = 0.45
U_off = U_on/3

@named schmitt_trigger = SchmittTrigger(U_on=U_on, U_off=U_off)

st_sol = simulate_system(schmitt_trigger; tspan=tspan, adaptive=false, dt=0.005)

interp_st = st_sol(times)

fig4 = Figure()
ax41 = Axis(fig4[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax41, times, rad2deg.(interp_st[plant.ϕ]))
hlines!(ax41, [rad2deg(setpoint)], linestyle=:dash)

fig4
save("assets/posts/sac-thrusters/code/st-sim.svg", fig4) #hide