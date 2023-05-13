# This file was generated, do not modify it. # hide
@named scl = LinearSpacecraftAttitude(u0=[0.5, 0.25, -0.5])

scl_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(setpoint_sca.output, feedback_θ.input1),
    connect(setpoint_sca.output, feedback_ψ.input1),

    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, torque_ϕ.tau),
    connect(torque_ϕ.flange, scl.x_flange_a),
    connect(scl.ϕ_sensor.phi, feedback_ϕ.input2),

    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, torque_θ.tau),
    connect(torque_θ.flange, scl.y_flange_a),
    connect(scl.θ_sensor.phi, feedback_θ.input2),

    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, torque_ψ.tau),
    connect(torque_ψ.flange, scl.z_flange_a),
    connect(scl.ψ_sensor.phi, feedback_ψ.input2),
]

@named scl_model = ODESystem(scl_eqs, t; systems = [
    scl, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

scl_sys = structural_simplify(scl_model)

scl_prob = ODEProblem(scl_sys, [], (0, 2.5), [])
scl_sol = solve(scl_prob, Tsit5())