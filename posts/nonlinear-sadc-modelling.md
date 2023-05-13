@def title = "Non-Linear Spacecraft Attitude Dynamics and Control Modelling"
@def published = "May 13th, 2023"
@def tags = ["Programming", "Julia", "Blogging", "Modelling", "Control Systems"]

<!-- @def reeval = true -->

# Non-Linear Spacecraft Attitude Dynamics and Control Modelling

_By Michal Jagodzinski - May 13th, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/Nz8TnLwQw68)
@@

@@img-caption
Photo by [Hunter Reilly](https://unsplash.com/photos/Nz8TnLwQw68)
@@

We return for some more acausal, component-based modelling with Julia and `ModelingToolkit.jl`. [In my previous post](https://michaszj.github.io/starcoffee/posts/acausal-sadc-modelling/), I defined and simulated a linear model for the attitude dynamics of spacecraft. In this post, I implement the more realistic, non-linear version and compare its performance with the linearized form.

## Brief Aside: Spacecraft Attitude Dynamics

<!-- prettier-ignore -->
The attitude dynamics of a spacecraft are governed by [Euler's rotation equations](https://en.wikipedia.org/wiki/Euler%27s_equations_(rigid_body_dynamics)), defined as:

$$ \mathbf J \dot{\mathbf \omega} + \mathbf \omega^\times \mathbf J \mathbf \omega = \mathbf M $$

The expanded form of these equations, assuming the principal axes form (i.e., the inertia matrix is diagonal), are defined as:

$$ \begin{align*} J_x \dot \omega_x + (J_z - J_y) \omega_y \omega_z &= M_x \\ J_x \dot \omega_y + (J_x - J_z) \omega_x \omega_z &= M_y \\ J_z \dot \omega_z + (J_y - J_x) \omega_x \omega_y &= M_z \end{align*} $$

As can be clearly seen, these equations are non-linear. Thus, to allow for linear analysis, the equations can be linearized by removing the non-linear terms:

$$ \begin{align*} J_x \dot \omega_x &= M_x \\ J_x \dot \omega_y &= M_y \\ J_z \dot \omega_z &= M_z \end{align*} $$

These are the equations of motion that govern the linear model I defined in the previous post. For small angles and angular velocities, the linear equations are decent approximations for the non-linear ones. Regardless, this linearized form does not model the attitude dynamics of a spacecraft completely accurately. By no means is it useless, linear models are still incredibly useful for design and analysis. Linear systems can be analyzed using linear control theory, which gives engineers great insight into the behaviour of systems.

However, it is still useful to have a non-linear model for further analysis, and that is what we'll be covering in this post.

## Defining the Non-Linear Model

Imports and defining useful constants:

```julia:imports
using CairoMakie, AlgebraOfGraphics
using ModelingToolkit, ModelingToolkitStandardLibrary
using DifferentialEquations
set_aog_theme!()

@parameters t
const Rot = ModelingToolkitStandardLibrary.Mechanical.Rotational
const B = ModelingToolkitStandardLibrary.Blocks
```

Defining the custom component:

```julia:nonlinear-comp
@component function SpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=100.0, u0=zeros(3), ω0=zeros(3), ω̇0=zeros(3)
)

    @named Mx = B.RealInput()
    @named My = B.RealInput()
    @named Mz = B.RealInput()

    @named phi_x = B.RealOutput()
    @named phi_y = B.RealOutput()
    @named phi_z = B.RealOutput()

    sts = @variables ϕ(t)=u0[1] θ(t)=u0[2] ψ(t)=u0[3] ωx(t)=ω0[1] ωy(t)=ω0[2] ωz(t)=ω0[3] ω̇x(t)=ω̇0[1] ω̇y(t)=ω̇0[2] ω̇z(t)=ω̇0[3]

    ps = @parameters Jx=Jx Jy=Jy Jz=Jz u0=u0 ω0=ω0 ω̇0=ω̇0

    D = Differential(t)

    eqs = [
        phi_x.u ~ ϕ,
        phi_y.u ~ θ,
        phi_z.u ~ ψ,

        D(ϕ) ~ ωx + ωz * tan(θ)*cos(ϕ) + ωy*tan(θ)*sin(ϕ),
        D(θ) ~ ωy*cos(ϕ) - ωz*sin(ϕ),
        D(ψ) ~ ωz*sec(θ)*cos(ϕ) + ωy*sec(θ)*sin(ϕ),

        D(ωx) ~ ω̇x,
        D(ωy) ~ ω̇y,
        D(ωz) ~ ω̇z,

        Jx * ω̇x ~ Mx.u + (Jy - Jz)*ωy*ωz,
        Jy * ω̇y ~ My.u + (Jz - Jx)*ωx*ωz,
        Jz * ω̇z ~ Mz.u + (Jx - Jy)*ωx*ωy,
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), Mx, My, Mz, phi_x, phi_y, phi_z
    )
end
```

This component is defined using an [Euler angle](https://en.wikipedia.org/wiki/Euler_angles) attitude representation. Specifically, this uses the 3-2-1 rotation sequence. The `Mx`, `My`, and `Mz` variables are used as the torque inputs to the system, and the resulting Euler angles of the spacecraft can be accessed using the `phi_x`, `phi_y`, and `phi_z` variables.

Next, let's recreate the [control example from my previous post](https://michaszj.github.io/starcoffee/posts/acausal-sadc-modelling/#pid_control_example) using this non-linear model:

```julia:components
@named sc = SpacecraftAttitude(u0=[0.5, 0.25, -0.5])

@named setpoint_sca = B.Constant(k=0)

@named feedback_ϕ = B.Feedback()
@named feedback_θ = B.Feedback()
@named feedback_ψ = B.Feedback()

@named ctrl_ϕ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ϕ = Rot.Torque()

@named ctrl_θ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_θ = Rot.Torque()

@named ctrl_ψ = B.PID(k=10.0, Td=32.0, Ti=100)
@named torque_ψ = Rot.Torque()

sca_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, sc.Mx),
    connect(sc.phi_x, feedback_ϕ.input2),

    connect(setpoint_sca.output, feedback_θ.input1),
    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, sc.My),
    connect(sc.phi_y, feedback_θ.input2),

    connect(setpoint_sca.output, feedback_ψ.input1),
    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, sc.Mz),
    connect(sc.phi_z, feedback_ψ.input2),
]
```

Just as a reminder, here is the block diagram of one axis of the system we are implementing:

@@im-100
\fig{sim-diagram}
@@

This block diagram represents the following connections:

```julia
connect(setpoint_sca.output, feedback_ϕ.input1),
connect(feedback_ϕ.output, ctrl_ϕ.err_input),
connect(ctrl_ϕ.ctr_output, sc.Mx),
connect(sc.phi_x, feedback_ϕ.input2),
```

Next, we can solve the system and plot the results:

```julia:nonlinear-sim
@named sca_model = ODESystem(sca_eqs, t; systems = [
    sc, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

sca_sys = structural_simplify(sca_model)

sca_prob = ODEProblem(sca_sys, [], (0, 2.5), [])
sca_sol = solve(sca_prob, Tsit5())
```

```julia:nonlinear-vis
times = 0:0.01:2.5
nonlinear_interp = sca_sol(times)

fig1 = Figure()
ax1 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax1, times, rad2deg.(nonlinear_interp[sc.ϕ]), label="ϕ (Roll)")
lines!(ax1, times, rad2deg.(nonlinear_interp[sc.θ]), label="θ (Pitch)")
lines!(ax1, times, rad2deg.(nonlinear_interp[sc.ψ]), label="ψ (Yaw)")

hlines!(ax1, [0.0]; label="Setpoint", linestyle=:dash)

axislegend(ax1)

fig1
save("assets/posts/nonlinear-sadc-modelling/code/nonlinear-sim.svg", fig1) #hide
```

@@im-75
\fig{nonlinear-sim}
@@

The results are pretty similar to the linear model, however some non-linear behaviour can be seen.

## Comparison with Linear Model

Let's bring in the linear model and compare its performance with the non-linear model:

```julia:linear-comp
@component function LinearSpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=100.0, u0=[0.0,0.0,0.0], ω0=[0.0,0.0,0.0], ω̇0=[0.0,0.0,0.0]
)

    @named Ix = Rot.Inertia(J=Jx, phi_start=u0[1], w_start=ω0[1], a_start=ω̇0[1])
    @named Iy = Rot.Inertia(J=Jy, phi_start=u0[2], w_start=ω0[2], a_start=ω̇0[2])
    @named Iz = Rot.Inertia(J=Jz, phi_start=u0[3], w_start=ω0[3], a_start=ω̇0[3])

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

    D = Differential(t)

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

```julia:linear-sim
@named scl = LinearSpacecraftAttitude(u0=[0.5, 0.25, -0.5])

scl_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(setpoint_sca.output, feedback_θ.input1),
    connect(setpoint_sca.output, feedback_ψ.input1),

    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, torque_ϕ.tau),
    connect(torque_ϕ.flange, scl.x_flange_a),
    connect(scl.ϕ_sensor.phi, feedback_ϕ.input2),

    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, torque_θ.tau),
    connect(torque_θ.flange, scl.y_flange_a),
    connect(scl.θ_sensor.phi, feedback_θ.input2),

    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, torque_ψ.tau),
    connect(torque_ψ.flange, scl.z_flange_a),
    connect(scl.ψ_sensor.phi, feedback_ψ.input2),
]

@named scl_model = ODESystem(scl_eqs, t; systems = [
    scl, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
])

scl_sys = structural_simplify(scl_model)

scl_prob = ODEProblem(scl_sys, [], (0, 2.5), [])
scl_sol = solve(scl_prob, Tsit5())
```

```julia:comp-vis
fig2 = Figure(resolution=(1000,500))
ax21 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Angle (°)", title="ϕ")

linear_interp = scl_sol(times)

lines!(ax21, times, rad2deg.(nonlinear_interp[sc.ϕ]))
lines!(ax21, times, rad2deg.(linear_interp[scl.Ix.phi]), linestyle=:dash)

ax22 = Axis(fig2[1,2], xlabel="Time (s)", title="θ")

lines!(ax22, times, rad2deg.(nonlinear_interp[sc.θ]))
lines!(ax22, times, rad2deg.(linear_interp[scl.Iy.phi]), linestyle=:dash)


ax23 = Axis(fig2[1,3], xlabel="Time (s)", title="ψ")

lines!(ax23, times, rad2deg.(nonlinear_interp[sc.ψ]), label="Non-Linear")
lines!(ax23, times, rad2deg.(linear_interp[scl.Iz.phi]), linestyle=:dash, label="Linear")

fig2[2, 2] = Legend(
    fig2, ax23, "Model", framevisible=false, orientation=:horizontal, tellwidth=false
)

fig2
save("assets/posts/nonlinear-sadc-modelling/code/comp-vis.svg", fig2) #hide
```

@@im-100
\fig{comp-vis.svg}
@@

As can be seen, the performance of the non-linear model is somewhat similar to the linear one. For the $\theta$ Euler angle however, the non-linear effects are quite prominent.

## Implementing Actuator Dynamics

Let's further complicate matters with our model. So far we have been assuming that the torque applied to the spacecraft from the controllers is instantaneous. In real life however, it sometimes takes the actuator some time to "ramp up" to the desired torque. This is especially true for reaction wheels. For reaction wheels, the first-order transfer function is a reasonable model[^1] for its dynamics:

$$ \frac{U(s)}{U_c(s)} = \frac{1}{T s + 1} $$

Where $T > 0$. This is a transfer system for the actual actuator output $U(s)$ from the controller output $U_c(s)$.

Thus, to simulate actuator dynamics, we can introduce a first-order filter to the simulation using the `FirstOrder` block from the `ModelingToolkit.jl` standard library. This block is then connected between the controller output and the spacecraft torque input:

```julia:ad-sys
actuator_T = 0.05
@named ad_ϕ = B.FirstOrder(T=actuator_T)
@named ad_θ = B.FirstOrder(T=actuator_T)
@named ad_ψ = B.FirstOrder(T=actuator_T)

sc_ad_eqs = [
    connect(setpoint_sca.output, feedback_ϕ.input1),
    connect(feedback_ϕ.output, ctrl_ϕ.err_input),
    connect(ctrl_ϕ.ctr_output, ad_ϕ.input),
    connect(ad_ϕ.output, sc.Mx),
    connect(sc.phi_x, feedback_ϕ.input2),

    connect(setpoint_sca.output, feedback_θ.input1),
    connect(feedback_θ.output, ctrl_θ.err_input),
    connect(ctrl_θ.ctr_output, ad_θ.input),
    connect(ad_θ.output, sc.My),
    connect(sc.phi_y, feedback_θ.input2),

    connect(setpoint_sca.output, feedback_ψ.input1),
    connect(feedback_ψ.output, ctrl_ψ.err_input),
    connect(ctrl_ψ.ctr_output, ad_ψ.input),
    connect(ad_ψ.output, sc.Mz),
    connect(sc.phi_z, feedback_ψ.input2),
]

@named sc_ad_model = ODESystem(sc_ad_eqs, t; systems = [
    sc, setpoint_sca,
    feedback_ϕ, ctrl_ϕ, torque_ϕ,
    feedback_θ, ctrl_θ, torque_θ,
    feedback_ψ, ctrl_ψ, torque_ψ,
    ad_ϕ, ad_θ, ad_ψ
])

sc_ad_sys = structural_simplify(sc_ad_model)

sc_ad_prob = ODEProblem(sc_ad_sys, [], (0, 2.5), [])
sc_ad_sol = solve(sc_ad_prob)
```

Let's now visualize the Euler angles over time of this simulation, and compare these results to the two previous models:

```julia:comp-vis2
fig3 = Figure(resolution=(1000,500))
ax31 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)", title="ϕ")

ad_interp = sc_ad_sol(times)

lines!(ax31, times, rad2deg.(ad_interp[sc.ϕ]))
lines!(ax31, times, rad2deg.(nonlinear_interp[sc.ϕ]), linestyle=:dot)
lines!(ax31, times, rad2deg.(linear_interp[scl.Ix.phi]), linestyle=:dash)

ax32 = Axis(fig3[1,2], xlabel="Time (s)", title="θ")

lines!(ax32, times, rad2deg.(ad_interp[sc.θ]))
lines!(ax32, times, rad2deg.(nonlinear_interp[sc.θ]), linestyle=:dot)
lines!(ax32, times, rad2deg.(linear_interp[scl.Iy.phi]), linestyle=:dash)

ax33 = Axis(fig3[1,3], xlabel="Time (s)", title="ψ")

lines!(ax33, times, rad2deg.(ad_interp[sc.ψ]), label="Actuator Dynamics")
lines!(ax33, times, rad2deg.(nonlinear_interp[sc.ψ]), linestyle=:dot, label="Non-linear")
lines!(ax33, times, rad2deg.(linear_interp[scl.Iz.phi]), linestyle=:dash, label="Linear")

fig3[2, 2] = Legend(
    fig3, ax33, "Model", framevisible=false, orientation=:horizontal, tellwidth=false
)

fig3
save("assets/posts/nonlinear-sadc-modelling/code/comp-vis2.svg", fig3) #hide
```

@@im-100
\fig{comp-vis2.svg}
@@

With every iteration upon the linear model we implement, the performance of our controllers worsen, but we get closer to real-life behaviour.

## Wrapping Up

Thanks for reading, I hope this post was insightful. I've been having a great time learning `ModelingToolkit.jl` more, it really is an amazing package. I'm planning to keep learning it more and implementing more spacecraft attitude dynamics and controls stuff using it. I'm planning on implementing a lot of this work into [SAT](https://michaszj.github.io/starcoffee/posts/satellite-analysis-toolkit/), so expect some updates on that project soon. More posts soon, until next time.

## References

[^1]: A.H.J. de Ruiter, C.J. Damaren, J.R. Forbes, "Routh’s Stability Criterion," in _Spacecraft Dynamics and Control: An Introduction_, 1st Edition. West Sussex, UK: John Wiley & Sons Ltd., 2013.
