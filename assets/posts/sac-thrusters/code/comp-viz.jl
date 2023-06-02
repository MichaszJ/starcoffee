# This file was generated, do not modify it. # hide
fig7 = Figure()
ax71 = Axis(fig7[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax71, times, rad2deg.(interp_pwpf[plant.ϕ]), label="PWPF Modulator")
lines!(ax71, times, rad2deg.(interp_prm_alt[plant.ϕ]), label="Pseudorate Modulator")
lines!(ax71, times, rad2deg.(interp_st[plant.ϕ]), label="Schmitt Trigger")
lines!(ax71, times, rad2deg.(interp_bbdz[plant.ϕ]), label="Bang-Bang with Deadzone Controller")
lines!(ax71, times, rad2deg.(interp[plant.ϕ]), label="Bang-Bang Controller")

hlines!(ax71, [rad2deg(setpoint)], linestyle=:dash)

axislegend(ax71, position=:rb)

fig7
save("assets/posts/sac-thrusters/code/comp-viz.svg", fig7) #hide