# This file was generated, do not modify it. # hide
@named model = ODESystem(
    eqs, t; systems = [torque_input, torque, inertia]
)

sys = structural_simplify(model)
ls = latexify(sys) #hide
println(ls.s) # hide