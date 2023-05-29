# This file was generated, do not modify it. # hide
@component function Thruster(; name, thrust, lever_arm)
    @named ctrl_input = B.RealInput()
    @named torque_out = B.RealOutput()

    sts = @variables u(t) M(t)
    ps = @parameters thrust=thrust lever_arm=lever_arm

    eqs = [
        M ~ u * lever_arm * thrust,

        u ~ ctrl_input.u,
        torque_out.u ~ M
    ]

    ODESystem(eqs, t, sts, ps; systems=[ctrl_input, torque_out], name = name)
end

@component function SimpleSpacecraftPlant(; name, J=100.0, ϕ0=0.0, ω0=0.0)
    @named torque_in = B.RealInput()

    @named ϕ_out = B.RealOutput()
    @named ω_out = B.RealOutput()

    sts = @variables ϕ(t)=ϕ0 ω(t)=ω0
    ps = @parameters J=J ϕ0=ϕ0 ω0=ω0

    D = Differential(t)

    eqs = [
        D(ϕ) ~ ω,
        D(ω) ~ torque_in.u / J,

        ϕ_out.u ~ ϕ,
        ω_out.u ~ ω
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), torque_in, ϕ_out, ω_out
    )
end