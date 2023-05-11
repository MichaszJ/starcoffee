# This file was generated, do not modify it. # hide
@named simple_model = ODESystem(simple_eqs, t; systems = [
    torque_input, torque, spacecraft
])

simple_sys = structural_simplify(simple_model)

simple_prob = ODEProblem(simple_sys, [], (0, 5*60.0), [])
simple_sol = solve(simple_prob, Tsit5())