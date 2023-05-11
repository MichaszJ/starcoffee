# This file was generated, do not modify it. # hide
times_ctrl = 0:0.01:2.5
ctrl_sol_interp = ctrl_sol(times_ctrl)

fig3 = Figure()
ax3 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Ix.phi]), label="ϕ (Roll)")
lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Iy.phi]), label="θ (Pitch)")
lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Iz.phi]), label="ψ (Yaw)")

hlines!(ax3, [0.0]; label="Setpoint", linestyle=:dash)

axislegend(ax3)

fig3
save("assets/posts/acausal-sadc-modelling/code/ctrl-vis.svg", fig3) #hide