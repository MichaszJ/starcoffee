# This file was generated, do not modify it. # hide
ctrl_eqs = [
    connect(setpoint.output, feedback_ϕ.input1),
    connect(setpoint.output, feedback_θ.input1),
    connect(setpoint.output, feedback_ψ.input1),

    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, torque_ϕ.tau),
    connect(torque_ϕ.flange, ctrl_spacecraft.x_flange_a),
    connect(ctrl_spacecraft.ϕ_sensor.phi, feedback_ϕ.input2),

    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, torque_θ.tau),
    connect(torque_θ.flange, ctrl_spacecraft.y_flange_a),
    connect(ctrl_spacecraft.θ_sensor.phi, feedback_θ.input2),

    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, torque_ψ.tau),
    connect(torque_ψ.flange, ctrl_spacecraft.z_flange_a),
    connect(ctrl_spacecraft.ψ_sensor.phi, feedback_ψ.input2),
]