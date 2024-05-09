# This file was generated, do not modify it. # hide
@component function PWPFModulator(; name, time_constant, filter_gain, U_on, U_off, torque)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    @named trigger = SchmittTrigger(U_on=U_on, U_off=U_off)
    @named filter = B.FirstOrder(T=time_constant, k=filter_gain)
    @named feedback = B.Feedback()
    @named normalization = B.StaticNonLinearity(u -> clamp(u/torque, -1, 1))

    eqs = [
        connect(ref_signal, normalization.input),
        connect(normalization.output, feedback.input1),
        connect(feedback.output, filter.input),
        connect(filter.output, trigger.ref_signal),
        connect(trigger.ctrl_output, feedback.input2),
        connect(trigger.ctrl_output, ctrl_output),
    ]

    ODESystem(eqs, t, [], []; systems=[trigger, filter, feedback, ref_signal, ctrl_output, normalization], name = name)
end