# This file was generated, do not modify it. # hide
times = 0:0.01:2.5
nonlinear_interp = sca_sol(times)

fig1 = Figure()
ax1 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax1, times, rad2deg.(nonlinear_interp[sc.ϕ]), label="ϕ (Roll)")
lines!(ax1, times, rad2deg.(nonlinear_interp[sc.θ]), label="θ (Pitch)")
lines!(ax1, times, rad2deg.(nonlinear_interp[sc.ψ]), label="ψ (Yaw)")

hlines!(ax1, [0.0]; label="Setpoint", linestyle=:dash)

axislegend(ax1)

fig1
save("assets/posts/nonlinear-sadc-modelling/code/nonlinear-sim.svg", fig1) #hide