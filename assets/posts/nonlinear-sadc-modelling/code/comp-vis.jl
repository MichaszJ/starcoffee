# This file was generated, do not modify it. # hide
fig2 = Figure(resolution=(1000,500))
ax21 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Angle (°)", title="ϕ")

linear_interp = scl_sol(times)

lines!(ax21, times, rad2deg.(nonlinear_interp[sc.ϕ]))
lines!(ax21, times, rad2deg.(linear_interp[scl.Ix.phi]), linestyle=:dash)

ax22 = Axis(fig2[1,2], xlabel="Time (s)", title="θ")

lines!(ax22, times, rad2deg.(nonlinear_interp[sc.θ]))
lines!(ax22, times, rad2deg.(linear_interp[scl.Iy.phi]), linestyle=:dash)


ax23 = Axis(fig2[1,3], xlabel="Time (s)", title="ψ")

lines!(ax23, times, rad2deg.(nonlinear_interp[sc.ψ]), label="Non-Linear")
lines!(ax23, times, rad2deg.(linear_interp[scl.Iz.phi]), linestyle=:dash, label="Linear")

fig2[2, 2] = Legend(
    fig2, ax23, "Model", framevisible=false, orientation=:horizontal, tellwidth=false
)

fig2
save("assets/posts/nonlinear-sadc-modelling/code/comp-vis.svg", fig2) #hide