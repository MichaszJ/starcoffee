@def title = "SAT Work Log 2"
@def published = "April 4th, 2023"
@def tags = ["Julia", "Programming", "Blogging", "Satellite Analysis Toolkit", "Work Log"]

# SAT Work Log 2

_By Michal Jagodzinski - Work Log - April 4th, 2023_

\tableofcontents

<!-- @def reeval = true -->

@@im-100
![](https://source.unsplash.com/DKix6Un55mw)
@@

@@img-caption
Photo by [Johannes Plenio](https://unsplash.com/photos/DKix6Un55mw)
@@

Welcome to the second Satellite Analysis Toolkit work log. I've been busy fleshing things out a bit, so let's get into it.

## GroundTracker Work

I've decided to rename OrbitTool to GroundTracker, I think the new name makes a lot more sense than the old one. Plus I'm planning on making a tool that focuses only on simulating orbits, so the name 'OrbitTool' will fit better in that case. I've also been working on cleaning up the UI a bit:

@@im-100
\fig{groundtracker.png}
@@

`Makie.jl` is a little finicky to work with regarding UI, as it's primarily a plotting library. But with some finesse it does work.

For further interactivity (multiple satellites, ground stations, and visibility analysis), I would probably need to implement a separate program that outputs files that then gets read in by GroundTracker. I am not sure how I'd be able to implement that level of interactivity using just `Makie.jl`.

You can find the source code here: [satellite-analysis-toolkit/src/GroundTracker.jl](https://github.com/MichaszJ/satellite-analysis-toolkit/blob/main/src/GroundTracker.jl)

## Orbital Dynamics Work

I started working on the foundational orbital dynamics code that will be powering upcoming interactive components in SAT. First up, the [two-body problem](https://en.wikipedia.org/wiki/Two-body_problem). The source code for this section can be found here: [satellite-analysis-toolkit/src/TwoBody.jl](https://github.com/MichaszJ/satellite-analysis-toolkit/blob/main/src/TwoBody.jl).

The dynamics of two masses $m_1$ and $m_2$ under each-other's influence of gravity can be described by the following differential equations:

$$
\begin{align*}
\ddot{\mathbf{R}}_{1} &= G m_{2} \frac{\mathbf{r}}{r^3} \\
\ddot{\mathbf{R}}_{2} &= G m_{1} \frac{\mathbf{r}}{r^3}
\end{align*}
$$

These two equations can be further expanded into six separate scalar differential equations:

$$
\begin{align*}
\ddot{x}_{1} &= G m_{2} \frac{x_{2} - x_1}{r^3} \\
\ddot{y}_{1} &= G m_{2} \frac{y_{2} - y_1}{r^3} \\
\ddot{z}_{1} &= G m_{2} \frac{z_{2} - z_1}{r^3} \\
\ddot{x}_{2} &= G m_{1} \frac{x_{1} - x_2}{r^3} \\
\ddot{y}_{2} &= G m_{1} \frac{y_{1} - y_2}{r^3} \\
\ddot{z}_{2} &= G m_{1} \frac{z_{1} - z_2}{r^3}
\end{align*}
$$

Where $r=\sqrt{ (x_{2}-x_{1})^2+(y_{2}-y_{1})^2+(z_{2}-z_{1})^2 }$[^1].

For the actual numerical simulation work, I will be using `ModelingToolkit.jl` along with `DifferentialEquations.jl`. I am also starting to use `Unitful.jl` throughout SAT to ensure values are actually correct and to provide functionality for unit conversions and other potential features. Let's get to some code. First, the required imports:

```julia:imports
using Plots, ModelingToolkit, DifferentialEquations, Unitful
```

To implement the two-body problem in `ModelingToolkit.jl`, we first must define the variables and parameters of the system:

```julia:definitions
@variables(begin
    t, [unit=u"s"],
    x₁(t), [unit=u"m"],
    y₁(t), [unit=u"m"],
    z₁(t), [unit=u"m"],
    ẋ₁(t), [unit=u"m/s"],
    ẏ₁(t), [unit=u"m/s"],
    ż₁(t), [unit=u"m/s"],
    x₂(t), [unit=u"m"],
    y₂(t), [unit=u"m"],
    z₂(t), [unit=u"m"],
    ẋ₂(t), [unit=u"m/s"],
    ẏ₂(t), [unit=u"m/s"],
    ż₂(t), [unit=u"m/s"],
    r(t), [unit=u"m"]
end)

D = Differential(t)

@parameters G [unit=u"N*m^2/kg^2"] m₁ [unit=u"kg"] m₂ [unit=u"kg"]
```

As can be seen, I am also defining the SI units for each variable and parameter as well. I find the syntax for including units in `ModelingToolkit.jl` somewhat messy, hopefully this gets improved at some point but for now it's not too bad.

Then we define the equations of the system using the variables and parameters:

```julia:eqns
two_body_equations = [
    r ~ sqrt((x₂ - x₁)^2 + (y₂ - y₁)^2 + (z₂ - z₁)^2),

    D(x₁) ~ ẋ₁,
    D(y₁) ~ ẏ₁,
    D(z₁) ~ ż₁,

    D(ẋ₁) ~ G*m₂*(x₂ - x₁)/r^3,
    D(ẏ₁) ~ G*m₂*(y₂ - y₁)/r^3,
    D(ż₁) ~ G*m₂*(z₂ - z₁)/r^3,

    D(x₂) ~ ẋ₂,
    D(y₂) ~ ẏ₂,
    D(z₂) ~ ż₂,

    D(ẋ₂) ~ G*m₁*(x₁ - x₂)/r^3,
    D(ẏ₂) ~ G*m₁*(y₁ - y₂)/r^3,
    D(ż₂) ~ G*m₁*(z₁ - z₂)/r^3,
]
```

Next, we define the `ModelingToolkit.jl` system variable:

```julia:sys
diffeq_two_body_system = structural_simplify(ODESystem(
    two_body_equations,
    t,
    name=:two_body_system
))
```

With the system defined, we can now simulate some orbits. I'm going to simulate an interesting orbit found in _Orbital Mechanics for Engineering Students_, with the following initial conditions:

```julia:init
u₀ = Dict(
    x₁ => 0.0u"m",
    y₁ => 0.0u"m",
    z₁ => 0.0u"m",
    ẋ₁ => 10.0u"km/s",
    ẏ₁ => 20.0u"km/s",
    ż₁ => 30.0u"km/s",
    x₂ => 3000.0u"km",
    y₂ => 0.0u"m",
    z₂ => 0.0u"m",
    ẋ₂ => 0.0u"m/s",
    ẏ₂ => 40.0u"km/s",
    ż₂ => 0.0u"m/s"
)
```

As can be seen, I am defining some units in kilometres instead of just metres, as those values were the ones given in the textbook. `Unitful.jl` takes care of the conversions. Next, we define the parameters of the system:

```julia:params
p = Dict(
    G => 6.6743e-11u"N*m^2/kg^2",
    m₁ => 10e26u"kg",
    m₂ => 10e26u"kg"
)
```

Before defining the ODE problem variable, I am also going to define a helper function. I found this function in the [`ModelingToolkit.jl` docs](https://docs.sciml.ai/ModelingToolkit/dev/basics/Validation/#Parameter-and-Initial-Condition-Values), and it allows for the usage of units in the initial conditions and parameters `Dict`s. Normally, `ModelingToolkit.jl` expects the values in those `Dict`s to be normal values with the proper conversion applied, without `Unitful.jl` units. However, the following function removes the units and applies the proper conversions automatically for you:

```julia:helper
function remove_units(p::Dict)
    Dict(k => Unitful.ustrip(ModelingToolkit.get_unit(k), v) for (k, v) in p)
end
```

This is useful as it allows us to define our initial conditions and parameters with any arbitrary units we want, without worrying about converting the values ourselves. Although the output from the solution will be in the units defined for the system's variables.

Next, we define the ODE problem variable:

```julia:prob
two_body_problem = ODEProblem(
    diffeq_two_body_system,
    remove_units(u₀),
    (0.0, 480.0),
    remove_units(p),
    jac=true
)
```

As can be seen, this is where we have to use the previously mentioned `remove_units()` function to remove the units in the initial conditions and parameters `Dict`s.

With the problem defined, we can calculate the solution:

```julia:sol
two_body_sol = solve(two_body_problem, Tsit5())
```

With the solution found, we can now plot the orbits of the two masses:

```julia:plot
times = 0.0:0.01:480.0
interp = two_body_sol(times)

plot(interp[x₁], interp[y₁], interp[z₁], label="Mass 1", dpi=300)
plot!(interp[x₂], interp[y₂], interp[z₂], label="Mass 2")
savefig(joinpath(@OUTPUT, "orbit-plot.svg")) # hide
```

@@im-100
\fig{orbit-plot}
@@

Pretty neat.

This is only the first orbit propagator I will be implementing. I will also be adding the three-body and circular-restricted three-body propagators, potentially some others as well. I don't have too much cool stuff to show regarding orbital dynamics yet, but I am just laying the groundwork for now. Expect some interesting applications soon enough.

## Wrapping Up

I've been having a blast working on SAT for the past week as of writing, as well as on this blog. I hope those of you reading are finding my work interesting and/or useful. The aim is to keep writing pretty consistently and put out posts every couple days or so. I'm also slowly updating the style of this blog as well, so hopefully it'll be a lot nicer to look at soon. However, I am still focusing on a minimalistic style.

Thanks for reading! Until next time.

## References

[^1]: H.D. Curtis, "Equations of Motion in an Inertial Frame," in _Orbital Mechanics for Engineering Students_, Revised 4th Edition. Amsterdam, NL: Elsevier Ltd., 2021, ch. 2, sec. 2, pp. 59.
