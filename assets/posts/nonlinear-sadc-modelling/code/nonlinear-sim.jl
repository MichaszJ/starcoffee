# This file was generated, do not modify it. # hide
@named sca_model = ODESystem(sca_eqs, t; systems = [
    sc, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

sca_sys = structural_simplify(sca_model)

sca_prob = ODEProblem(sca_sys, [], (0, 2.5), [])
sca_sol = solve(sca_prob, Tsit5())