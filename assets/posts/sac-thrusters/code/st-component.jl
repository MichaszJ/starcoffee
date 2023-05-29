# This file was generated, do not modify it. # hide
@component function SchmittTrigger(; name, U_on, U_off)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables u(t)

    eqs = [
        u ~ _schmitt_behaviour_model(ref_signal.u, U_on, U_off),
        ctrl_output.u ~ u
    ]

    ODESystem(eqs, t, sts, []; systems=[ref_signal, ctrl_output], name = name)
end