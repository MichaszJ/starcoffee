# This file was generated, do not modify it. # hide
@named sc = SpacecraftAttitude(u0=[0.5, 0.25, -0.5])

@named setpoint_sca = B.Constant(k=0)

@named feedback_ϕ = B.Feedback()
@named feedback_θ = B.Feedback()
@named feedback_ψ = B.Feedback()

@named ctrl_ϕ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ϕ = Rot.Torque()

@named ctrl_θ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_θ = Rot.Torque()

@named ctrl_ψ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ψ = Rot.Torque()

sca_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, sc.Mx),
    connect(sc.phi_x, feedback_ϕ.input2),

    connect(setpoint_sca.output, feedback_θ.input1),
    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, sc.My),
    connect(sc.phi_y, feedback_θ.input2),

    connect(setpoint_sca.output, feedback_ψ.input1),
    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, sc.Mz),
    connect(sc.phi_z, feedback_ψ.input2),
]