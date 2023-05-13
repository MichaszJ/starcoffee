# This file was generated, do not modify it. # hide
fig3 = Figure(resolution=(1000,500))
ax31 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)", title="ϕ")

ad_interp = sc_ad_sol(times)

lines!(ax31, times, rad2deg.(ad_interp[sc.ϕ]))
lines!(ax31, times, rad2deg.(nonlinear_interp[sc.ϕ]), linestyle=:dot)
lines!(ax31, times, rad2deg.(linear_interp[scl.Ix.phi]), linestyle=:dash)

ax32 = Axis(fig3[1,2], xlabel="Time (s)", title="θ")

lines!(ax32, times, rad2deg.(ad_interp[sc.θ]))
lines!(ax32, times, rad2deg.(nonlinear_interp[sc.θ]), linestyle=:dot)
lines!(ax32, times, rad2deg.(linear_interp[scl.Iy.phi]), linestyle=:dash)

ax33 = Axis(fig3[1,3], xlabel="Time (s)", title="ψ")

lines!(ax33, times, rad2deg.(ad_interp[sc.ψ]), label="Actuator Dynamics")
lines!(ax33, times, rad2deg.(nonlinear_interp[sc.ψ]), linestyle=:dot, label="Non-linear")
lines!(ax33, times, rad2deg.(linear_interp[scl.Iz.phi]), linestyle=:dash, label="Linear")

fig3[2, 2] = Legend(
    fig3, ax33, "Model", framevisible=false, orientation=:horizontal, tellwidth=false
)

fig3
save("assets/posts/nonlinear-sadc-modelling/code/comp-vis2.svg", fig3) #hide