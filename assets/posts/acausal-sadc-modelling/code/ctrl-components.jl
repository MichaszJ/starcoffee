# This file was generated, do not modify it. # hide
@named ctrl_spacecraft = LinearSpacecraftAttitude(
    Jx=150.0, Jy=100.0, Jz=100.0, u0=[0.5, 0.25, -0.5]
)

@named setpoint = B.Constant(k=0.0)

@named feedback_ϕ = B.Feedback()
@named feedback_θ = B.Feedback()
@named feedback_ψ = B.Feedback()

@named ctrl_ϕ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ϕ = Rot.Torque()

@named ctrl_θ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_θ = Rot.Torque()

@named ctrl_ψ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ψ = Rot.Torque()