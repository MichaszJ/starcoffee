@def title = "Modelling Spacecraft Attitude Control with Thrusters"
@def subtitle = "Simulating active spacecraft attitude control using thrusters"
@def published = "May 29th, 2023"
@def author = "Michal Jagodzinski"
@def tags = ["Blogging", "Julia", "Programming", "Aerospace", "Control Systems"]

@def mintoclevel=1

<!-- @def reeval = true -->

{{ generate_title "sac-thrusters.md" }}

@@im-100
![](https://source.unsplash.com/PPoWdNggYu8)
@@

@@img-caption
Photo by [Marek Piwnicki](https://unsplash.com/photos/PPoWdNggYu8)
@@

Hello and welcome back to Star Coffee. We continue developing our spacecraft attitude dynamics and control simulations, this time by implementing attitude control using thrusters.

\tableofcontents

# Introduction to Attitude Control with Thrusters

The challenge of using thrusters for attitude control is the fact that the thrust they produce is not able to be throttled. In other words, the torque is on or off, 100% or 0%. Proportional thrusters do exist but are not typically used[^1].

In my previous posts related to spacecraft attitude control, we have been simulating the responses of spacecraft to continuous torque values. If we want to simulate using thrusters, we have to implement some new controllers that have an either on or off torque output to the spacecraft.

The most simple controller we can use for controlling thrusters is the [bang-bang controller](https://en.wikipedia.org/wiki/Bang%E2%80%93bang_control). The control law is defined as:

$$
u(t) = \begin{cases}
  U \text{sign} (r(t))  & |r(t)| > 0 \\
  0 & r(t) = 0
\end{cases}
$$

Where $u$ is the controller output, $U$ is the thruster's torque, and $r$ is a reference signal, which is the output of another controller such as a PID controller. This control law is quite intuitive, if the error is greater than zero, the thruster(s) activate to correct the error. This control law is quite crude and leads to poor performance.

A slightly better control law is the bang-bang controller with a deadzone:

$$
u(t) = \begin{cases}
  U \text{sign} (r(t))  & |r(t)| \geq \alpha \\
  0 & |r(t)| < \alpha
\end{cases}
$$

This controller is quite similar except it has a deadzone of width $2\alpha$, where it does not fire.

Next we have the [Schmitt trigger](https://en.wikipedia.org/wiki/Schmitt_trigger), similar to the bang-bang controller with deadzone. In this case this control law is defined with a block diagram:

@@im-75
\fig{schmitt-trigger}
@@

This control law functions by activating when the reference signal reaches a trigger threshold, $U_\text{on}$, and deactivates once it reaches an off threshold, $U_\text{off}$. The Schmitt trigger is a very useful, and it will be a core part of the next two control laws we will be looking at.

The next controllers we will be looking at are a class of controllers called pulse modulators. First we have the pseudorate modulator or derived-rate modulator:

@@im-75
\fig{prm}
@@

As can be seen, this controller builds upon the Schmitt trigger and adds in a first-order filter with time constant $T_m$ and filter gain $K_m$.

The next controller, the pulse-width pulse-frequency modulator is very similar to the pseudorate modulator[^2] :

@@im-75
\fig{pwpf}
@@

# Implementing Thruster Controllers with ModelingToolkit.jl

Alright, let's implement these controllers with `ModelingToolkit.jl`. For simplicity, we will only be implementing these controllers along one axis of a spacecraft.

```julia:imports
using CairoMakie, AlgebraOfGraphics
using ModelingToolkit, ModelingToolkitStandardLibrary
using DifferentialEquations
set_aog_theme!()

@parameters t
const B = ModelingToolkitStandardLibrary.Blocks
```

Let's create simple components to model a thruster and the spacecraft:

```julia:model-components
@component function Thruster(; name, thrust, lever_arm)
    @named ctrl_input = B.RealInput()
    @named torque_out = B.RealOutput()

    sts = @variables u(t) M(t)
    ps = @parameters thrust=thrust lever_arm=lever_arm

    eqs = [
        M ~ u * lever_arm * thrust,

        u ~ ctrl_input.u,
        torque_out.u ~ M
    ]

    ODESystem(eqs, t, sts, ps; systems=[ctrl_input, torque_out], name = name)
end

@component function SimpleSpacecraftPlant(; name, J=100.0, ϕ0=0.0, ω0=0.0)
    @named torque_in = B.RealInput()

    @named ϕ_out = B.RealOutput()
    @named ω_out = B.RealOutput()

    sts = @variables ϕ(t)=ϕ0 ω(t)=ω0
    ps = @parameters J=J ϕ0=ϕ0 ω0=ω0

    D = Differential(t)

    eqs = [
        D(ϕ) ~ ω,
        D(ω) ~ torque_in.u / J,

        ϕ_out.u ~ ϕ,
        ω_out.u ~ ω
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), torque_in, ϕ_out, ω_out
    )
end
```

## Bang-Bang Controller

Let's start by simulating the basic bang-bang controller. First we create the component for the controller:

```julia:bb-component
@component function BBController(; name, thruster_torque)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables ref(t) u(t)
    ps = @parameters thruster_torque=thruster_torque

    eqs = [
        u ~ thruster_torque*sign(ref),

        ref ~ ref_signal.u,
        ctrl_output.u ~ u
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), ref_signal, ctrl_output
    )
end
```

Next let's set up the simulation. For the reference signal, we'll obtain it by using the `LimPID` block from the MTK standard library:

```julia:bb-sim-setup
setpoint = deg2rad(10)
@named θ_ref = B.Constant(k=setpoint)

J = 100
ωn = 0.5
ζ = 1.3

Kp = J*ωn^2
Kd = 2*J*ωn*ζ

@named ref_controller = B.LimPID(k=Kp, Td=Kd, Ti=1, gains=true)

F = 1
L = 1
@named thruster = Thruster(thrust=F, lever_arm=L)

@named plant = SimpleSpacecraftPlant(J=J)

F = 1
L = 1
@named bangbang_controller = BBController(thruster_torque=L*F)
```

Next I'll define a helper function to run the simulation with different controllers:

```julia:sim-helper
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
```

This function just takes care of composing the system and running the simulation automatically, and returns the solution object. The block diagram for this system is:

@@im-100
\fig{sys-diagram}
@@

Let's simulate the system with a bang-bang controller and plot the results:

```julia:bb-sim
tspan=[0.0, 180.0]

bb_sol = simulate_system(bangbang_controller; tspan=tspan)

times = 0:0.1:tspan[2]
interp = bb_sol(times)

fig1 = Figure()
ax11 = Axis(fig1[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax11, times, rad2deg.(interp[plant.ϕ]))
hlines!(ax11, [rad2deg(setpoint)], linestyle=:dash)

bracket!(120, 10, 180, 10, offset=5, text="Inset Area", style=:square, orientation=:down)

ax12 = Axis(fig1, bbox = BBox(400, 750, 200, 450))

lines!(ax12, 120:0.1:180, rad2deg.(bb_sol(120:0.1:180)[plant.ϕ]))
hlines!(ax12, [rad2deg(setpoint)], linestyle=:dash)

fig1
save("assets/posts/sac-thrusters/code/bb-sim.svg", fig1) #hide
```

@@im-100
\fig{bb-sim}
@@

As can be seen in the inset plot, the bang-bang controller causes the spacecraft to oscillate rapidly as it reaches the setpoint. Let's take a look at the control output from the controller in the 120-180 second time range:

```julia:bb-ss-plot
fig2 = Figure()
ax21 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Controller Output")

lines!(ax21, 120:0.1:180, bb_sol(120:0.1:180)[bangbang_controller.ctrl_output.u])

fig2
save("assets/posts/sac-thrusters/code/bb-ss.svg", fig2) #hide
```

@@im-100
\fig{bb-ss}
@@

The controller output is indeed incredibly oscillatory, causing the thruster to fire and stop incredibly rapidly. This causes a lot of unnecessary fuel usage, as well as the fact that real thrusters probably would not be able to pulse at these high frequencies.

## Bang-Bang with Deadzone Controller

Next, let's take a look at a bang-bang controller with a deadzone to hopefully alleviate the steady-state oscillations. Let's define the component for this controller and simulate the same scenario as the previous:

```julia:bbdz-sim
@component function BBDZController(; name, thruster_torque, deadzone_α)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables ref(t) u(t)
    ps = @parameters thruster_torque=thruster_torque

    eqs = [
        u ~ (abs(ref) ≥ deadzone_α) * thruster_torque*sign(ref),

        ref ~ ref_signal.u,
        ctrl_output.u ~ u
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), ref_signal, ctrl_output
    )
end

α = 0.05
@named bangbangdz_controller = BBDZController(thruster_torque=L*F, deadzone_α=α)

bbdz_sol = simulate_system(bangbangdz_controller; tspan=tspan)

interp_bbdz = bbdz_sol(times)

fig3 = Figure()
ax31 = Axis(fig3[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax31, times, rad2deg.(interp_bbdz[plant.ϕ]))
hlines!(ax31, [rad2deg(setpoint)], linestyle=:dash)

bracket!(120, 10, 180, 10, offset=5, text="Inset Area", style=:square, orientation=:down)

ax32 = Axis(fig3, bbox = BBox(400, 750, 200, 450))

lines!(ax32, 120:0.1:180, rad2deg.(bbdz_sol(120:0.1:180)[plant.ϕ]))

hlines!(ax32, [rad2deg(setpoint)], linestyle=:dash)

fig3
save("assets/posts/sac-thrusters/code/bbdz-sim.svg", fig3) #hide
```

@@im-100
\fig{bbdz-sim}
@@

As can be seen, there is still some oscillations, as the controller is unable to completely stop the spacecraft from rotating. However, these oscillations are a lot lower frequency, resulting in much less vibration and fuel expenditure. The deadzone parameter $\alpha$ can also be tuned to provide the controller behaviour required.

## Schmitt Trigger

The Schmitt trigger itself is an electric circuit, however we'll just be implementing a function that models the behaviour of the trigger. I don't like the way this is done currently, but it's the best I can do:

```julia:st-function
global_switch = 0

function _schmitt_behaviour_model(u, U_on, U_off; total_torque=1)
    global global_switch

    clamped_u = clamp(u/total_torque, -1, 1)

    if sign(clamped_u) > 0
        if clamped_u ≥ U_on && global_switch == 0
            global_switch = 1
        elseif clamped_u ≤ U_off && global_switch == 1
            global_switch = 0
        end
    else
        if clamped_u ≤ -U_on && global_switch == 0
            global_switch = -1
        elseif clamped_u ≥ -U_off && global_switch == -1
            global_switch = 0
        end
    end

    return global_switch
end

@register_symbolic _schmitt_behaviour_model(u, U_on, U_off)
```

We use the `@register_symbolic` macro to allow for the underlying `Symbolics.jl` types used in MTK to be used for boolean operations.

Next the Schmitt trigger component is defined as:

```julia:st-component
@component function SchmittTrigger(; name, U_on, U_off)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    sts = @variables u(t)

    eqs = [
        u ~ _schmitt_behaviour_model(ref_signal.u, U_on, U_off),
        ctrl_output.u ~ u
    ]

    ODESystem(eqs, t, sts, []; systems=[ref_signal, ctrl_output], name = name)
end
```

Simulating and plotting the results of the Schmitt trigger:

```julia:st-sim
U_on = 0.45
U_off = U_on/3

@named schmitt_trigger = SchmittTrigger(U_on=U_on, U_off=U_off)

st_sol = simulate_system(schmitt_trigger; tspan=tspan, adaptive=false, dt=0.005)

interp_st = st_sol(times)

fig4 = Figure()
ax41 = Axis(fig4[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax41, times, rad2deg.(interp_st[plant.ϕ]))
hlines!(ax41, [rad2deg(setpoint)], linestyle=:dash)

fig4
save("assets/posts/sac-thrusters/code/st-sim.svg", fig4) #hide
```

@@im-100
\fig{st-sim}
@@

## Pseudorate Modulator

Next, we enhance the behaviour of the Schmitt trigger by using it to create the pseudorate modulator:

```julia:prm-component
@component function PseudorateModulator(; name, time_constant, filter_gain, U_on, U_off)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    @named trigger = SchmittTrigger(U_on=U_on, U_off=U_off)
    @named filter = B.FirstOrder(T=time_constant, k=filter_gain)
    @named feedback = B.Feedback()

    eqs = [
        connect(ref_signal, feedback.input1),
        connect(feedback.output, trigger.ref_signal),
        connect(trigger.ctrl_output, filter.input),
        connect(trigger.ctrl_output, ctrl_output),
        connect(filter.output, feedback.input2),
    ]

    ODESystem(eqs, t, [], []; systems=[trigger, filter, feedback, ref_signal, ctrl_output], name = name)
end
```

Simulating and plotting the results of the pseudorate modulator:

```julia:prm-sim
K_m = 4.5
T_m = 0.85

@named prm = PseudorateModulator(time_constant=T_m, filter_gain=K_m, U_on=U_on, U_off=U_off)

prm_sol = simulate_system(prm; tspan=tspan, adaptive=false, dt=0.005)

interp_prm = prm_sol(times)

fig5 = Figure()
ax51 = Axis(fig5[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax51, times, rad2deg.(interp_prm[plant.ϕ]))
hlines!(ax51, [rad2deg(setpoint)], linestyle=:dash)

fig5
save("assets/posts/sac-thrusters/code/prm-sim.svg", fig5) #hide
```

@@im-100
\fig{prm-sim}
@@

## PWPF Modulator

Finally, let's define the component for our last and hopefully best performing controller, the PWPF modulator:

```julia:pwpf-component
@component function PWPFModulator(; name, time_constant, filter_gain, U_on, U_off)
    @named ref_signal = B.RealInput()
    @named ctrl_output = B.RealOutput()

    @named trigger = SchmittTrigger(U_on=U_on, U_off=U_off)
    @named filter = B.FirstOrder(T=time_constant, k=filter_gain)
    @named feedback = B.Feedback()

    eqs = [
        connect(ref_signal, feedback.input1),
        connect(feedback.output, filter.input),
        connect(filter.output, trigger.ref_signal),
        connect(trigger.ctrl_output, feedback.input2),
        connect(trigger.ctrl_output, ctrl_output),
    ]

    ODESystem(eqs, t, [], []; systems=[trigger, filter, feedback, ref_signal, ctrl_output], name = name)
end
```

Simulating and plotting the results of the PWPF modulator:

```julia:pwpf-sim
@named pwpf = PWPFModulator(time_constant=T_m, filter_gain=K_m, U_on=U_on, U_off=U_off)

pwpf_sol = simulate_system(pwpf; tspan=tspan, adaptive=false, dt=0.005)

interp_pwpf = pwpf_sol(times)

fig6 = Figure()
ax61 = Axis(fig6[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax61, times, rad2deg.(interp_pwpf[plant.ϕ]))
hlines!(ax61, [rad2deg(setpoint)], linestyle=:dash)

fig6
save("assets/posts/sac-thrusters/code/pwpf-sim.svg", fig6) #hide
```

@@im-100
\fig{pwpf-sim}
@@

## Controller Comparison

Let's now compare the quite different behaviours of every controller we've implemented:

```julia:comp-viz
fig7 = Figure()
ax71 = Axis(fig7[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax71, times, rad2deg.(interp_pwpf[plant.ϕ]), label="PWPF Modulator")
lines!(ax71, times, rad2deg.(interp_prm[plant.ϕ]), label="Pseudorate Modulator")
lines!(ax71, times, rad2deg.(interp_st[plant.ϕ]), label="Schmitt Trigger")
lines!(ax71, times, rad2deg.(interp_bbdz[plant.ϕ]), label="Bang-Bang with Deadzone Controller")
lines!(ax71, times, rad2deg.(interp[plant.ϕ]), label="Bang-Bang Controller")

hlines!(ax71, [rad2deg(setpoint)], linestyle=:dash)

axislegend(ax71, position=:rb)

fig7
save("assets/posts/sac-thrusters/code/comp-viz.svg", fig7) #hide
```

@@im-100
\fig{comp-viz}
@@

# Wrapping Up

In conclusion, we have succesfully simulated various thruster controllers for spacecraft attitude control. Other controllers exist however I selected a handful that are easily able to be simulated using `ModelingToolkit.jl`, nevertheless controllers such as the pseudorate and PWPF modulators are commonly used. I hoped this post is useful and informative!

On another note, I really don't like the way I had to implement the behaviour model of a Schmitt trigger. If any readers have some suggestions to better implement the behaviour, ideally within the `SchmittTrigger` component itself, please reach out!

Thanks for reading, until next time.

# Footnotes and References

[^1]: "Proportional thrusters, whose fuel valves open a distance proportional to the commanded thrust level, are not employed much in practice. Mechanical considerations prohibit proportional valve operation largely because of dirt particles that prevent complete closure for small valve openings; fuel leakage through the valves consequently produces opposing thruster firings." B. Wie, "Rotational Maneuvers and Attitude Control" in _Space Vehicle Dynamics and Control_, 2nd Ed., Reston, VA, USA: American Institute of Aeronautics and Astronautics, Inc., 2008.
[^2]: T.D. Krøvel, ["Optimal Tuning of PWPF Modulator for Attitude Control,"](https://folk.ntnu.no/tomgra/Diplomer/Krovel.pdf) M.S. thesis, Department of Engineering Cybernetics, Norwegian University of Science and Technology, Trondheim, 2005.