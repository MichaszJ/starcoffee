# This file was generated, do not modify it. # hide
@named ctrl_model = ODESystem(ctrl_eqs, t; systems = [
    ctrl_spacecraft, setpoint,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

ctrl_sys = structural_simplify(ctrl_model)

ctrl_prob = ODEProblem(ctrl_sys, [], (0, 2.5), [])
ctrl_sol = solve(ctrl_prob, Tsit5())