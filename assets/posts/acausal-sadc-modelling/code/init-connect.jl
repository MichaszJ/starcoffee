# This file was generated, do not modify it. # hide
eqs = [
    connect(torque_input.output, torque.tau),
    connect(torque.flange, inertia.flange_a)
]