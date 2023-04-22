@def title = "Simulating Rocket Launches with Julia"
@def published = "April 21st, 2023"
@def tags = ["Julia", "Programming", "Aerospace", "Blogging"]

# Simulating Rocket Launches with Julia

_By Michal Jagodzinski - April 21st, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/FFbGDH7yHc4)
@@

@@img-caption
Photo by [Abhishek Tanwar](https://unsplash.com/photos/FFbGDH7yHc4)
@@

Inspired by the somewhat successful launch of SpaceX's Starship rocket earlier this week, I've decided to go over using Julia and `ModelingToolkit.jl` to simulate rocket launches. Let's get into it.

## Rocket Vehicle Dynamics

For these simulations, we will be using a specific reference frame and state to describe the dynamics of rockets. This frame is described by the following figure:

@@im-100
\fig{rocket-dynamics.svg}
@@

The downrange distance $x$ and altitude $h$ rates of change in terms of tangential speed $v$ and flight path angle $\gamma$ are defined as:

$$
\begin{align*}
\dot{x} &= \frac{R_e}{R_e + h} v \cos \gamma \\
\dot{h} &= v \sin \gamma
\end{align*}
$$

The rate of change of the rocket's tangential speed is defined as:

$$
\begin{align*} \dot{v} &= \frac{T}{m} - \frac{D}{m} - g \sin \gamma \\
\end{align*}
$$

Where $R_E$ is the radius of Earth, $T$ is the rocket engine's thrust, $D$ is atmospheric drag, and $g$ is acceleration due to gravity. Since altitude varies over time, $g$ at any arbitrary altitude can be defined as:

$$ g = \frac{g_0}{(1 + h/R_e)^2} $$

Where $g_0$ is the gravitational acceleration at the surface of Earth.

The atmospheric drag is defined as:

$$ D = \frac{1}{2} \rho v^2 A C_D $$

Where $\rho$ is the air density, $A$ is the frontal area of the rocket, and $C_D$ is the coefficient of drag. The air density can be approximated at any arbitrary altitude as:

$$ \rho = \rho_0 e^{-h/h_0} $$

Where $\rho_0$ is the standard air density at sea level, and $h_0$ is the reference altitude, 7.5 km.

In addition, we also need to account for change in mass due to fuel expenditure from the rocket engine. The rate of change of the rocket's mass is equal to the negative mass-flow rate of the rocket engine, given by:

$$\dot{m}_\text{rocket} = - \dot{m}_e = - \frac{T}{I_\text{sp} g_0}$$

Where $I_\text{sp}$ is the rocket engine's [specific impulse](https://en.wikipedia.org/wiki/Specific_impulse).

For this initial case, we are assuming the flight path angle and thrust of the rocket remains constant.

With all the math out of the way, let's finally get into some code. First we import the required libraries:

```julia
using ModelingToolkit, OrdinaryDiffEq
```

Next we initialize the required variables, parameters, and some constants:

```julia
@variables t x(t) h(t) v(t) γ(t) m(t) g(t) ρ(t) D(t)

dt = Differential(t)

@parameters Iₛₚ T A CD

const g₀ = 9.80665
const Rₑ = 6378e3
const ρ₀ = 1.225
const h₀ = 7.5e3
```

Next we can define the system of equations to model the rocket:

```julia
basic_system = ODESystem(
    [
        g ~ g₀/(1 + h/Rₑ)^2,
        ρ ~ ρ₀*exp(-h/h₀),
        D ~ 0.5 * ρ * v^2 * A * CD,

        dt(x) ~ (Rₑ/(Rₑ + h))*v*cos(γ),
        dt(h) ~ v*sin(γ),
        dt(v) ~ T/m - D/m - g*sin(γ),
        dt(γ) ~ 0,
        dt(m) ~ -T/(Iₛₚ * g₀),
    ],
    t,
    name=:basic_system
) |> structural_simplify
```

Now we can define the initial conditions, parameters, and timespan of an example rocket:

```julia
u₀ = Dict(
    x => 0.0,
    h => 0.0,
    v => 0.0,
    γ => deg2rad(89.85),
    m => 50000,
)

p = Dict(
    Iₛₚ => 390.0,
    T => 525e3,
    A => π*(5)^2/4,
    CD => 0.5,
)

tspan_basic = [0.0, 260.0]
```

Finally, we can define the `ODEProblem` and solve it:

```julia
basic_prob = ODEProblem(basic_system, u₀, tspan_basic, p, jac=true)
basic_sol = solve(basic_prob, Tsit5())
```

Which gives the following result:

@@im-75
\fig{fig1.svg}
@@

As can be seen, the rocket ends up getting to a pretty high altitude, almost 400 km. For reference, [the Karman line](https://en.wikipedia.org/wiki/K%C3%A1rm%C3%A1n_line), the conventional boundary at which space begins, is at 100 km. So our rocket ends up in space, but not for long. Unfortunately, _staying in space_ is a lot harder than just getting there.

The problem with getting into orbit is that a spacecraft requires a lot of velocity, not just altitude. For a better shot at actually getting into orbit, let's take a look at a [gravity turn launch trajectory](https://en.wikipedia.org/wiki/Gravity_turn).

## Gravity Turn Trajectories

In a gravity turn trajectory, the flight path angle of the rocket is no longer constant, it slowly changes as the rocket ascends up into the atmosphere. In this case, the flight path angle has a rate of change defined by:

$$\dot{\gamma} = -\frac{1}{\gamma} \left(g - \frac{v^2}{R_E + h} \right) \cos \gamma$$

We can include the equation above[^1] in the definition for a gravity turn system:

```julia
gravity_turn_system = ODESystem(
    [
        g ~ g₀/(1 + h/Rₑ)^2,
        ρ ~ ρ₀*exp(-h/h₀),
        D ~ 0.5 * ρ * v^2 * A * CD,

        dt(x) ~ (Rₑ/(Rₑ + h))*v*cos(γ),
        dt(h) ~ v*sin(γ),
        dt(v) ~ T/m - D/m - g*sin(γ),
        dt(γ) ~ -(1/v) * (g - v^2 / (Rₑ + h)) * cos(γ),
        dt(m) ~ -T/(Iₛₚ * g₀),
    ],
    t,
    name=:gravity_turn_system
) |> structural_simplify
```

Just for reference, here is the ODE system used to generate the freefall sections of the rocket flights:

```julia
freefall_system = ODESystem(
    [
        g ~ g₀/(1 + h/Rₑ)^2,
        ρ ~ ρ₀*exp(-h/h₀),
        D ~ 0.5 * ρ * v^2 * A * CD,

        dt(x) ~ (Rₑ/(Rₑ + h))*v*cos(γ),
        dt(h) ~ v*sin(γ),
        dt(v) ~ -D/m - g*sin(γ),
        dt(γ) ~ -(1/v) * (g - v^2 / (Rₑ + h)) * cos(γ),
        dt(m) ~ 0,
    ],
    t,
    name=:freefall_system
) |> structural_simplify
```

When launching, a rocket does not enter a gravity turn from the start. It starts to pitch over some time after launch. So, we set the example initial conditions for the gravity turn system to be:

```julia
u_gravity_turn = Dict(
    x => 0.0,
    h => 200.0,
    v => 180.0,
    γ => deg2rad(89.95),
    m => 50000.0,
)
```

This gives the following result:

@@im-100
\fig{fig2.svg}
@@

As can be seen, this rocket ends up much further downrange than the previous one, and gets to a much higher lateral velocity, which is needed to reach orbit.

In this example we simulated a single-stage rocket, meaning that the entire rocket was composed of one discrete system without any other disposable parts. Multi-stage rockets, such as the SpaceX Starship are used for actually reaching orbit. The Starship rocket that launched a couple days ago failed because the first stage didn't separate from the second.

## Wrapping Up

Thanks for reading! I hope this post was interesting. I am trying to further increase the quality of my writing and focusing more on visuals, I hope you were able to see some noticeable improvements. I plan to return to the topic of launch vehicles, including simulating a rocket actually getting into orbit.

Until next time.

## References

[^1]: H.D. Curtis, "Rocket Vehicle Dynamics," in _Orbital Mechanics for Engineering Students_, Revised 4th Edition. Amsterdam, NL: Elsevier Ltd., 2021.
