# This file was generated, do not modify it. # hide
function simulate_system(controller; tspan=[0.0, 120.0], solver_kwargs...)
    system_eqs = [
        connect(θ_ref.output, ref_controller.reference),
        connect(ref_controller.ctr_output, controller.ref_signal),
        connect(controller.ctrl_output, thruster.ctrl_input),
        connect(thruster.torque_out, plant.torque_in),
        connect(plant.ϕ_out, ref_controller.measurement),
    ]

    @named model = ODESystem(
        system_eqs, t; systems = [
            θ_ref, ref_controller, thruster, plant, controller
        ]
    )
    sys = structural_simplify(model)

    prob = ODEProblem(sys, [], tspan, [])
    sol = solve(prob; solver_kwargs...)
end