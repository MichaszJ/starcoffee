# This file was generated, do not modify it. # hide
actuator_T = 0.05
@named ad_ϕ = B.FirstOrder(T=actuator_T)
@named ad_θ = B.FirstOrder(T=actuator_T)
@named ad_ψ = B.FirstOrder(T=actuator_T)

sc_ad_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, ad_ϕ.input),
    connect(ad_ϕ.output, sc.Mx),
    connect(sc.phi_x, feedback_ϕ.input2),

    connect(setpoint_sca.output, feedback_θ.input1),
    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, ad_θ.input),
    connect(ad_θ.output, sc.My),
    connect(sc.phi_y, feedback_θ.input2),

    connect(setpoint_sca.output, feedback_ψ.input1),
    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, ad_ψ.input),
    connect(ad_ψ.output, sc.Mz),
    connect(sc.phi_z, feedback_ψ.input2),
]

@named sc_ad_model = ODESystem(sc_ad_eqs, t; systems = [
    sc, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
    ad_ϕ, ad_θ, ad_ψ
])

sc_ad_sys = structural_simplify(sc_ad_model)

sc_ad_prob = ODEProblem(sc_ad_sys, [], (0, 2.5), [])
sc_ad_sol = solve(sc_ad_prob)