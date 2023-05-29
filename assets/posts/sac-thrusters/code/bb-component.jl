# This file was generated, do not modify it. # hide
@component function BBController(; name, thruster_torque)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables ref(t) u(t)
    ps = @parameters thruster_torque=thruster_torque

    eqs = [
        u ~ thruster_torque*sign(ref),

        ref ~ ref_signal.u,
        ctrl_output.u ~ u
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), ref_signal, ctrl_output
    )
end