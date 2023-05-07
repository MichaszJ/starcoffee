# This file was generated, do not modify it. # hide
function terminate_conditions(out, u, t, integrator)
    out[1] = u[3]              # projectile hits ground
    out[2] = target2[1] - u[1] # projectile should've hit target
end

terminate_affect!(integrator, idx) = terminate!(integrator)

terminate_callback = VectorContinuousCallback(
    terminate_conditions, terminate_affect!, 2
)

function simulate_projectile2(ẋ0, ẏ0; tspan=[0.0, 15.0])
    u0 = [
        x => 0.0,
        ẋ => ẋ0,
        y => 0.0,
        ẏ => ẏ0
    ]

    prob = ODEProblem(sys, u0, tspan, jac=true)

    return solve(prob, Tsit5(), callback=terminate_callback)
end