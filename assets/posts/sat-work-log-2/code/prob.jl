# This file was generated, do not modify it. # hide
two_body_problem = ODEProblem(
    diffeq_two_body_system,
    remove_units(u₀),
    (0.0, 480.0),
    remove_units(p),
    jac=true
)