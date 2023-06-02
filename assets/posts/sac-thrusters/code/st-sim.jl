# This file was generated, do not modify it. # hide
U_on = 0.45
U_off = U_on/3

@named schmitt_trigger = SchmittTrigger(U_on=U_on, U_off=U_off)

# custom system for schmitt trigger including a normalization block
@named normalization = B.StaticNonLinearity(u -> clamp(u/(F*L), -1, 1))
system_eqs_norm = [
    connect(θ_ref.output, ref_controller.reference),
    connect(ref_controller.ctr_output, normalization.input),
    connect(normalization.output, schmitt_trigger.ref_signal),
    connect(schmitt_trigger.ctrl_output, thruster.ctrl_input),
    connect(thruster.torque_out, plant.torque_in),
    connect(plant.ϕ_out, ref_controller.measurement),
]

@named model_norm = ODESystem(system_eqs_norm, t; systems = [θ_ref, ref_controller, thruster, plant, schmitt_trigger, normalization])
sys_norm = structural_simplify(model_norm)

prob_norm = ODEProblem(sys_norm, [], tspan, [])
st_sol = solve(prob_norm; adaptive=false, dt=0.005)

interp_st = st_sol(times)

fig4 = Figure()
ax41 = Axis(fig4[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax41, times, rad2deg.(interp_st[plant.ϕ]))
hlines!(ax41, [rad2deg(setpoint)], linestyle=:dash)

fig4
save("assets/posts/sac-thrusters/code/st-sim.svg", fig4) #hide