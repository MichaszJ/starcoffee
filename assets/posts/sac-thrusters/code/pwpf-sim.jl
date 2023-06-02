# This file was generated, do not modify it. # hide
@named pwpf = PWPFModulator(time_constant=T_m, filter_gain=K_m, U_on=U_on, U_off=U_off, torque=F*L)

pwpf_sol = simulate_system(pwpf; tspan=tspan, adaptive=false, dt=0.005)

interp_pwpf = pwpf_sol(times)

fig6 = Figure()
ax61 = Axis(fig6[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax61, times, rad2deg.(interp_pwpf[plant.ϕ]))
hlines!(ax61, [rad2deg(setpoint)], linestyle=:dash)

fig6
save("assets/posts/sac-thrusters/code/pwpf-sim.svg", fig6) #hide