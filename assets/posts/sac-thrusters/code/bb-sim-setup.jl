# This file was generated, do not modify it. # hide
setpoint = deg2rad(10)
@named θ_ref = B.Constant(k=setpoint)

J = 100
ωn = 0.5
ζ = 1.3

Kp = J*ωn^2
Kd = 2*J*ωn*ζ

@named ref_controller = B.LimPID(k=Kp, Td=Kd, Ti=1, gains=true)

F = 1
L = 1
@named thruster = Thruster(thrust=F, lever_arm=L)

@named plant = SimpleSpacecraftPlant(J=J)

F = 1
L = 1
@named bangbang_controller = BBController(thruster_torque=L*F)