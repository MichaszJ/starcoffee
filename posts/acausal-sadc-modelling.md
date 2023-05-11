@def title = "Acausal Spacecraft Attitude Dynamics and Control Modelling"
@def published = "May 10th, 2023"
@def tags = ["Programming", "Julia", "Blogging", "Modelling", "Control Systems"]

@def reeval = true

# Acausal Spacecraft Attitude Dynamics and Control Modelling

_By Michal Jagodzinski - May 10th, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/rG-1gfiQN0k)
@@

@@img-caption
Photo by [Kym MacKinnon](https://unsplash.com/photos/rG-1gfiQN0k)
@@

Hello and welcome back to Star Coffee. We return to more spacecraft GN&C related topics, this time using `ModelingToolkit.jl` and `ModelingToolkitStandardLibrary.jl` for acausal spacecraft attitude dynamics and control modelling. For a great overview of the differences between causal and acausal modelling, check out this talk from Dr. Chris Rackauckas: [Causal vs Acausal Modeling By Example: Why Julia ModelingToolkit.jl Scales](https://www.youtube.com/watch?v=ZYkojUozeC4).

## Getting Started with ModelingToolkitStandardLibrary.jl

```julia:imports
using CairoMakie, AlgebraOfGraphics, Latexify
using ModelingToolkit, ModelingToolkitStandardLibrary
using DifferentialEquations
set_aog_theme!()

@parameters t
const Rot = ModelingToolkitStandardLibrary.Mechanical.Rotational
const B = ModelingToolkitStandardLibrary.Blocks
```

[ModelingToolkitStandardLibrary.jl](https://docs.sciml.ai/ModelingToolkitStandardLibrary/stable/) is a standard library of reusable components used for acausal modelling with `ModelingToolkit.jl`. It has plenty of components from various types of systems, including mechanical, electrical, and thermal systems. Using this library allows for easily creating complex models from the smaller parts.

Let's do a simple example to illustrate how to build systems with `ModelingToolkitStandardLibrary.jl`. Let's simulate a small torque being applied to a body with some inertia. We define the components used in this system as:

```julia:init-components
@named torque_input = B.Constant(k=0.1)
@named torque = Rot.Torque()
@named inertia = Rot.Inertia(J=100.0)
```

Next we need to connect the components to form the system. The block diagram for the system is below:

@@im-75
\fig{init-diagram}
@@

In this diagram, each output from a component is connected to an input on another component, e.g., `torque_input.output` connects to `torque.tau`. Components have distinct connectors, which themselves are other components, and these connector objects are used to connect different components together. The connections for this system can be defined as:

```julia:init-connect
eqs = [
    connect(torque_input.output, torque.tau),
    connect(torque.flange, inertia.flange_a)
]
```

Next we can create the `ODESystem` object and simplify the system equations:

```julia:init-sys
@named model = ODESystem(
    eqs, t; systems = [torque_input, torque, inertia]
)

sys = structural_simplify(model)
ls = latexify(sys) #hide
println(ls.s) # hide
```

\textoutput{init-sys}

As can be seen, using `structural_simplify` reduces the system of equations down to just two. For reference, below is the full system of equations:

```julia:init-eqs
equations(model)
ls2 = latexify(equations(model)) #hide
println(ls2.s) # hide
```

\textoutput{init-eqs}

Finally we can define the `ODEProblem`, solve it, and plot the results:

```julia:init-sol
prob = ODEProblem(sys, [], (0, 5*60.0), [])
sol = solve(prob, Tsit5())

fig1 = Figure()
ax1 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (rad)")

lines!(ax1, 0:1:5*60, sol(0:1:5*60)[inertia.phi])

fig1
save("assets/posts/acausal-sadc-modelling/code/init-sol.svg", fig1) #hide
```

@@im-75
\fig{init-sol}
@@

## Creating a Linearized Spacecraft Attitude Model

Next, let's define a custom component to model the attitude dynamics of a spacecraft. This will be a linear model, utilizing the `Inertia` component we used for the previous example. To create the more accurate nonlinear model, we would need to define the system of differential equations ourselves.

This component is very similar to the previous system, except it now has three distinct axes, each with their own inertias.

```julia:model-def
@component function LinearSpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=100.0, u0=zeros(3), ω0=zeros(3), ω̇0=zeros(3)
)

    @named Ix = Rot.Inertia(
        J=Jx, phi_start=u0[1], w_start=ω0[1], a_start=ω̇0[1]
    )
    @named Iy = Rot.Inertia(
        J=Jy, phi_start=u0[2], w_start=ω0[2], a_start=ω̇0[2]
    )
    @named Iz = Rot.Inertia(
        J=Jz, phi_start=u0[3], w_start=ω0[3], a_start=ω̇0[3]
    )

    @named x_flange_a = Rot.Flange()
    @named y_flange_a = Rot.Flange()
    @named z_flange_a = Rot.Flange()

    @named x_flange_b = Rot.Flange()
    @named y_flange_b = Rot.Flange()
    @named z_flange_b = Rot.Flange()

    @named ϕ_sensor = Rot.AngleSensor()
    @named θ_sensor = Rot.AngleSensor()
    @named ψ_sensor = Rot.AngleSensor()

    ps = @parameters Jx=Jx Jy=Jy Jz=Jz u0=u0 ω0=ω0 ω̇0=ω̇0

    eqs = [
        connect(x_flange_a, Ix.flange_a),
        connect(y_flange_a, Iy.flange_a),
        connect(z_flange_a, Iz.flange_a),

        connect(Ix.flange_b, x_flange_b),
        connect(Iy.flange_b, y_flange_b),
        connect(Iz.flange_b, z_flange_b),

        connect(x_flange_b, ϕ_sensor.flange),
        connect(y_flange_b, θ_sensor.flange),
        connect(z_flange_b, ψ_sensor.flange),
    ]

    compose(
        ODESystem(eqs, t, [], ps; name = name),
        Ix, Iy, Iz,
        x_flange_a, y_flange_a, z_flange_a,
        x_flange_b, y_flange_b, z_flange_b,
        ϕ_sensor, θ_sensor, ψ_sensor
    )
end
```

## Recreating the Simple Example

With our custom component defined, let's recreate the previous example, but this time using our custom component we just defined.

```julia:simple-components
@named spacecraft = LinearSpacecraftAttitude()
```

Next we can reuse the previously defined components to create this simulation. This simulation is essentially the same as the previous:

@@im-75
\fig{sim-diagram}
@@

Creating the connections:

```julia:simple-connections
simple_eqs = [
    connect(torque_input.output, torque.tau),
    connect(torque.flange, spacecraft.x_flange_a)
]
```

Defining the model and running the simulation:

```julia:simple-sol
@named simple_model = ODESystem(simple_eqs, t; systems = [
    torque_input, torque, spacecraft
])

simple_sys = structural_simplify(simple_model)

simple_prob = ODEProblem(simple_sys, [], (0, 5*60.0), [])
simple_sol = solve(simple_prob, Tsit5())
```

It's as simple as that. We can now visualize the $\phi$ angle:

```julia:simple-vis
times = 0:1:5*60
ϕ_vec = simple_sol(times)[spacecraft.Ix.phi]

function handle_angle(angle)
    if abs(angle) > pi
        a = angle
        while a > pi
            a -= 2*pi
        end
        return a
    else
        return angle
    end
end

fig2 = Figure()
ax2 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax2, times, rad2deg.(handle_angle.(ϕ_vec)))

fig2
save("assets/posts/acausal-sadc-modelling/code/simple-vis.svg", fig2) #hide
```

@@im-75
\fig{simple-vis}
@@

Looks pretty good to me. This is pretty much the same solution I got [in a previous article of mine](https://michaszj.substack.com/p/spacecraft-attitude-control-with), so it's good to see my results should be correct.

## PID Control Example

Alright, now let's do a more complex example. Since we're using `ModelingToolkit.jl` for acausal modelling, building upon our model to create more complex simulations is incredibly easy. From the `ModelingToolkit.jl` standard library we get PID controllers for free, no additional setup is required. I'm sure as the ecosystem matures, we'll get things like Kalman filters and other useful components as well.

Let's now define our next spacecraft attitude simulation, this time using PID controllers to control all three axes. Here is the block diagram for this simulation setup:

@@im-100
\fig{simulation-diagram}
@@

This setup should be able to drive the spacecraft's attitude from an initial condition to a final setpoint. If you've taken a course on control systems this should look pretty familiar, it's just a simple feedback system. Let's define the components for this simulation:

```julia:ctrl-components
@named ctrl_spacecraft = LinearSpacecraftAttitude(
    Jx=150.0, Jy=100.0, Jz=100.0, u0=[0.5, 0.25, -0.5]
)

@named setpoint = B.Constant(k=0.0)

@named feedback_ϕ = B.Feedback()
@named feedback_θ = B.Feedback()
@named feedback_ψ = B.Feedback()

@named ctrl_ϕ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ϕ = Rot.Torque()

@named ctrl_θ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_θ = Rot.Torque()

@named ctrl_ψ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ψ = Rot.Torque()
```

Now let's define the connections:

```julia:ctrl-connections
ctrl_eqs = [
    connect(setpoint.output, feedback_ϕ.input1),
    connect(setpoint.output, feedback_θ.input1),
    connect(setpoint.output, feedback_ψ.input1),

    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, torque_ϕ.tau),
    connect(torque_ϕ.flange, ctrl_spacecraft.x_flange_a),
    connect(ctrl_spacecraft.ϕ_sensor.phi, feedback_ϕ.input2),

    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, torque_θ.tau),
    connect(torque_θ.flange, ctrl_spacecraft.y_flange_a),
    connect(ctrl_spacecraft.θ_sensor.phi, feedback_θ.input2),

    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, torque_ψ.tau),
    connect(torque_ψ.flange, ctrl_spacecraft.z_flange_a),
    connect(ctrl_spacecraft.ψ_sensor.phi, feedback_ψ.input2),
]
```

Defining the connections is a little tedious, but it's not a hard task. GUI tools such as [ModelingToolkitDesigner.jl](https://github.com/bradcarman/ModelingToolkitDesigner.jl) are already in development, and I'm excited to see how this and other tools built on `ModelingToolkit.jl` evolve. If we are able to get an open-source version of Simulink implemented in Julia I'll be incredibly happy.

Let's now simulate this system and plot the resulting angles over time of each axis:

```julia:ctrl-sol
@named ctrl_model = ODESystem(ctrl_eqs, t; systems = [
    ctrl_spacecraft, setpoint,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

ctrl_sys = structural_simplify(ctrl_model)

ctrl_prob = ODEProblem(ctrl_sys, [], (0, 2.5), [])
ctrl_sol = solve(ctrl_prob, Tsit5())
```

```julia:ctrl-vis
times_ctrl = 0:0.01:2.5
ctrl_sol_interp = ctrl_sol(times_ctrl)

fig3 = Figure()
ax3 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Ix.phi]), label="ϕ (Roll)")
lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Iy.phi]), label="θ (Pitch)")
lines!(ax3, times_ctrl, rad2deg.(ctrl_sol_interp[ctrl_spacecraft.Iz.phi]), label="ψ (Yaw)")

hlines!(ax3, [0.0]; label="Setpoint", linestyle=:dash)

axislegend(ax3)

fig3
save("assets/posts/acausal-sadc-modelling/code/ctrl-vis.svg", fig3) #hide
```

@@im-75
\fig{ctrl-vis}
@@

Looks good. As can be seen, the controllers successfully changed the attitude of the spacecraft to the setpoint. Obviously the PID controllers could be tuned to have better responses, but it's a good start. In addition to the spacecraft's attitude over time, we can also visualize the various states in our simulation. For example, let's see the torque inputs to the spacecraft from the controllers:

```julia:torque-vis
fig4 = Figure()
ax4 = Axis(fig4[1,1], xlabel="Time (s)", ylabel="Torque (N m)")

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.x_flange_a.tau],
    label="ϕ Controller Output"
)

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.y_flange_a.tau],
    label="θ Controller Output"
)

lines!(
    ax4, times_ctrl, ctrl_sol_interp[ctrl_spacecraft.z_flange_a.tau],
    label="ψ Controller Output"
)

axislegend(ax4)

fig4
save("assets/posts/acausal-sadc-modelling/code/torque-vis.svg", fig4) #hide
```

@@im-75
\fig{torque-vis}
@@

Sick. We get these additional states for analysis for free again. I did not code in this state or anything, I simply accessed the states from the `ctrl_spacecraft` component. Specific analysis points in the system can also be explicitly defined to conduct these kinds of analyses (see [this documentation](https://docs.sciml.ai/ModelingToolkitStandardLibrary/stable/API/linear_analysis/#ModelingToolkitStandardLibrary.Blocks.AnalysisPoint-Tuple{Any,%20Any}) for more info).

## Wrapping Up

Thanks for reading! Hope you learned something new and got inspired to give acausal modelling a try. I will continue learning about using `ModelingToolkit.jl` for acausal modelling and I am planning on creating these kinds of models within [SAT](https://michaszj.github.io/starcoffee/posts/satellite-analysis-toolkit/). More posts coming soon. Until next time.
