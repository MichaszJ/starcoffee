# This file was generated, do not modify it. # hide
@component function PseudorateModulatorAlt(; name, time_constant,  U_on, U_off, torque)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    @named trigger = SchmittTrigger(U_on=U_on, U_off=U_off)
    @named filter = B.FirstOrder(T=time_constant)
    @named feedback = B.Feedback()
    @named normalization = B.StaticNonLinearity(u -> clamp(u/torque, -1, 1))

    eqs = [
        connect(ref_signal, normalization.input),
        connect(normalization.output, feedback.input1),
        connect(feedback.output, trigger.ref_signal),
        connect(trigger.ctrl_output, filter.input),
        connect(trigger.ctrl_output, ctrl_output),
        connect(filter.output, feedback.input2),
    ]

    ODESystem(eqs, t, [], []; systems=[trigger, filter, feedback, ref_signal, ctrl_output, normalization], name = name)
end