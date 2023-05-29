# This file was generated, do not modify it. # hide
@component function BBDZController(; name, thruster_torque, deadzone_α)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables ref(t) u(t)
    ps = @parameters thruster_torque=thruster_torque

    eqs = [
        u ~ (abs(ref) ≥ deadzone_α) * thruster_torque*sign(ref),

        ref ~ ref_signal.u,
        ctrl_output.u ~ u
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), ref_signal, ctrl_output
    )
end

α = 0.05
@named bangbangdz_controller = BBDZController(thruster_torque=L*F, deadzone_α=α)

bbdz_sol = simulate_system(bangbangdz_controller; tspan=tspan)

interp_bbdz = bbdz_sol(times)

fig3 = Figure()
ax31 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax31, times, rad2deg.(interp_bbdz[plant.ϕ]))
hlines!(ax31, [rad2deg(setpoint)], linestyle=:dash)

bracket!(120, 10, 180, 10, offset=5, text="Inset Area", style=:square, orientation=:down)

ax32 = Axis(fig3, bbox = BBox(400, 750, 200, 450))

lines!(ax32, 120:0.1:180, rad2deg.(bbdz_sol(120:0.1:180)[plant.ϕ]))

hlines!(ax32, [rad2deg(setpoint)], linestyle=:dash)

fig3
save("assets/posts/sac-thrusters/code/bbdz-sim.svg", fig3) #hide