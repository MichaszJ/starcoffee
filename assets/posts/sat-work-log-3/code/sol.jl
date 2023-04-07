# This file was generated, do not modify it. # hide
three_body_problem = ODEProblem(
    diffeq_three_body_system,
    remove_units(u₀),
    [0.0, 10.0],
    remove_units(p),
    jac=true
)

three_body_sol = solve(three_body_problem, Vern7())