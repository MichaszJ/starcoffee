# This file was generated, do not modify it. # hide
earth_moon_cr_three_body_problem = ODEProblem(
    earth_moon_cr_three_body_system,
    u₀,
    [0.0, 3.4 * 24 * 60 * 60],
    [],
    jac=true
)

cr_three_body_sol = solve(earth_moon_cr_three_body_problem, Tsit5())