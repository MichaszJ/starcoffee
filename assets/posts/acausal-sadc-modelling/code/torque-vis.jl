# This file was generated, do not modify it. # hide
fig4 = Figure()
ax4 = Axis(fig4[1,1], xlabel="Time (s)", ylabel="Torque (N m)")

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.x_flange_a.tau],
    label="ϕ Controller Output"
)

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.y_flange_a.tau],
    label="θ Controller Output"
)

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.z_flange_a.tau],
    label="ψ Controller Output"
)

axislegend(ax4)

fig4
save("assets/posts/acausal-sadc-modelling/code/torque-vis.svg", fig4) #hide