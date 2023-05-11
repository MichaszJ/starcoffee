# This file was generated, do not modify it. # hide
simple_eqs = [
    connect(torque_input.output, torque.tau),
    connect(torque.flange, spacecraft.x_flange_a)
]