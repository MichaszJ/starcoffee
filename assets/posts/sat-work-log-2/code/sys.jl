# This file was generated, do not modify it. # hide
diffeq_two_body_system = structural_simplify(ODESystem(
    two_body_equations,
    t,
    name=:two_body_system
))