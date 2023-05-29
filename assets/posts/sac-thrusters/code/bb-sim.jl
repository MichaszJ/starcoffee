# This file was generated, do not modify it. # hide
tspan=[0.0, 180.0]

bb_sol = simulate_system(bangbang_controller; tspan=tspan)

times = 0:0.1:tspan[2]
interp = bb_sol(times)

fig1 = Figure()
ax11 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax11, times, rad2deg.(interp[plant.ϕ]))
hlines!(ax11, [rad2deg(setpoint)], linestyle=:dash)

bracket!(120, 10, 180, 10, offset=5, text="Inset Area", style=:square, orientation=:down)

ax12 = Axis(fig1, bbox = BBox(400, 750, 200, 450))

lines!(ax12, 120:0.1:180, rad2deg.(bb_sol(120:0.1:180)[plant.ϕ]))
hlines!(ax12, [rad2deg(setpoint)], linestyle=:dash)

fig1
save("assets/posts/sac-thrusters/code/bb-sim.svg", fig1) #hide