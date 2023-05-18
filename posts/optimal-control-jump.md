@def title = "Solving Optimal Control Problems with JuMP"
@def published = "May 17th, 2023"
@def tags = ["Programming", "Julia", "Blogging", "Optimal Control", "Numerical Methods"]

@def reeval = true

# Solving Optimal Control Problems with JuMP.jl

_By Michal Jagodzinski - May 17th, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/hnEdP-NdKMo)
@@

@@img-caption
Photo by [Melanie Magdalena](https://unsplash.com/photos/hnEdP-NdKMo)
@@

Hello and welcome back to Star Coffee. We return to the topic of [optimal control](https://en.wikipedia.org/wiki/Optimal_control), a field that I've been interested in (and struggling to learn) for a bit now. I'm not an expert on the theory yet, but I'm starting to get a grasp on using tools to solve optimal control problems.

In my [previous post on this topic](https://michaszj.github.io/starcoffee/posts/direct-shooting-with-approx/), we used Newton's method to solve the target hitting problem. The problem involves firing a projectile with some initial velocity in order to hit a target. We managed to implement an algorithm from scratch that finds a solution to the problem. However, if we are to cover more complicated optimal control problems, we're going to need to use some proper optimization tools to solve them. This is where [JuMP.jl](https://jump.dev/) comes in.

`JuMP.jl` is a domain-specific modelling language for mathematical optimization. It has support for a variety of optimization types, including linear programming, nonlinear programming, etc. Using `JuMP.jl` allows for setting up and solving optimization problems in an easy and consistent format, which I will demonstrate with two examples.

If you want to read more about `JuMP.jl`, I actually used it for part of my propulsion course project back in undergrad. I wrote about it on my Substack here: [Supersonic Inlet Design Using JuMP and Julia](https://michaszj.substack.com/p/supersonic-inlet-design-using-jump).

## Target Hitting Problem with JuMP

Let's get started on solving the target hitting problem by importing both `JuMP.jl` and `Ipopt.jl`, which is a wrapper for the [Ipopt](https://coin-or.github.io/Ipopt/) optimization solver. `JuMP.jl` on its own does not solve optimization problems, it only provides an easy and universal interface for optimization solvers.

```julia:imports
using JuMP, Ipopt, CairoMakie, AlgebraOfGraphics
set_aog_theme!()
```

Defining some values:

```julia:target-vals
# physical constants
g = 9.80665
m = 5.0
c = 0.25
vt = m*g / c

# target coordinates
xt = 180
yt = 20

# grid points for discretization
n = 50
```

Initializing the `JuMP` model and defining the timestep and state variables:

```julia:target-model
model = Model(Ipopt.Optimizer)
set_silent(model)

@variables(model, begin
    Δt ≥ 0, (start = 1 / n)
    x_proj[1:n] ≥ 0
    y_proj[1:n] ≥ 0

    0 ≤ vx_proj[1:n] ≤ 100
    vy_proj[1:n] ≤ 100
end)
```

Next, we set the boundary conditions and an initial guess for the initial velocity. For this scenario, the projectile starts at $(0,0)$, and we want it to end up hitting the target at $(180,20)$:

```julia:target-init-cond
# enforcing boundary conditions
fix(x_proj[1], 0; force=true)
fix(x_proj[n], xt; force=true)

fix(y_proj[1], 0; force=true)
fix(y_proj[n], yt; force=true)

# initial guess for initial velocity
set_start_value(vx_proj[1], 20)
set_start_value(vy_proj[1], 20)
```

Next, we define the acceleration terms of the system for use in the system dynamics. Essentially this step introduces more variables to the `JuMP` model, but these variables are not varied by the solver, we can just use them in other expressions:

```julia:target-exp
@NLexpressions(
    model,
    begin
        ax[j=1:n], -(g/vt)*vx_proj[j]
        ay[j=1:n], -g -(g/vt)*vy_proj[j]
    end
)
```

Next, we define the system dynamics using the trapezoidal integration rule. We enforce the system dynamics by setting them as constraints for all points past $t=0$:

```julia:target-dynamics
for j ∈ 2:n
    @NLconstraint(model,
        x_proj[j] == x_proj[j-1] + 0.5*Δt*(vx_proj[j] + vx_proj[j-1])
    )
    @NLconstraint(model,
        y_proj[j] == y_proj[j-1] + 0.5*Δt*(vy_proj[j] + vy_proj[j-1])
    )

    @NLconstraint(model,
        vx_proj[j] == vx_proj[j-1] + 0.5*Δt*(ax[j] + ax[j-1])
    )
    @NLconstraint(model,
        vy_proj[j] == vy_proj[j-1] + 0.5*Δt*(ay[j] + ay[j-1])
    )
end
```

Finally, we finish setting up the optimization problem by defining the objective function. Since we want an optimal initial velocity, we need to minimize the magnitude of the initial projectile velocity:

```julia:target-obj
@NLobjective(model, Min, sqrt(vx_proj[1]^2 + vy_proj[1]^2))
```

Optimizing the model:

```julia:target-optim
optimize!(model)
solution_summary(model)
```

\show{target-optim}

We now have the optimal initial velocity of the projectile in order to minimize the objective function $\sqrt{v_{x,0}^2 + v_{y,0}^2}$:

```julia:target-sol
value(vx_proj[1]), value(vy_proj[1])
```

\show{target-sol}

Plotting:

```julia:target-fig1
fig1 = Figure(resolution=(900,350))

ax11 = Axis(
    fig1[1,1], aspect = DataAspect(),
    xlabel="x (m)", ylabel="y (m)"
)

lines!(ax11, value.(x_proj)[:], value.(y_proj)[:])
scatter!(ax11, [xt], [yt])

fig1
save("assets/posts/optimal-control-jump/code/target-optim.svg", fig1) #hide
```

@@im-75
\fig{target-optim}
@@

Let's compare this solution to the one we achieved in the previous post on this topic:

@@im-75
\fig{target-hit-comp}
@@

It can clearly be seen that while both solutions hit the target, the finite difference solution appears to have a greater $x$ velocity. The `JuMP` solution has an initial projectile velocity magnitude of 49.12 m/s, whereas the finite difference solution has a magnitude of 51.95 m/s, about 5.5% less efficient.

This variation in solutions makes sense, when we were calculating the initial conditions using finite differences, we were minimizing the error between the target and the final projectile position. For the `JuMP` solution, we are instead minimizing the magnitude of the initial velocity.

## Hang Glider Range Maximization

Let's now cover a more complex problem. This time, we are trying to maximize the range a hang glider achieves in a thermal updraft. This scenario and all the equations/values comes from _Practical Methods for Optimal Control and Estimation Using Nonlinear Programming_.

> The state variables are $\mathbf{y}^\intercal(t) = (x,y,v_{x}, v_{y})$, where $x$ is the horizontal distance, $y$ is the altitude, $v_x$ is the horizontal velocity, and $v_y$ is the vertical velocity. The control variable is $u(t) = C_{L}$, the aerodynamic lift coefficient. The final time $t_{F}$ is free and the final range $x_{F}$ is to be maximized.

The state equations which describe the planar motion for the hang glider are:

$$
\dot{x} = v_{x}
$$

$$
\dot{y} = v_{y}
$$

$$
\dot{v}_{x} = \frac{1}{m} (- L \sin \eta - D \cos \eta)
$$

$$
\dot{v}_{y} = \frac{1}{m} (L \cos \eta - D \sin \eta - mg)
$$

With the quadratic drag polar

$$
C_{D} (C_{L}) = C_{0} + k C_{L}^2
$$

With expressions

$$
\begin{array}{cc}
D = \frac{1}{2} C_{D} \rho S v_{r}^2  & L = \frac{1}{2} C_{L} \rho S v_{r}^2 \\
 & \\
X = \left( \frac{x}{R} - 2.5 \right)^2 & u_{a}(x) = u_{M} (1 - X) e^{-X} \\
& \\
V_{y} = v_{y} - u_{a} (x)  & v_{r} = \sqrt{ v_{x}^2 + V_{y}^2 } \\
& \\
\sin \eta = \dfrac{V_{y}}{v_{r}}  &  \cos \eta = \dfrac{v_{x}}{v_{r}}
\end{array}
$$

With constants

$$
\begin{array}{cc}
u_{M} = 2.5  & m = 100 \\
& \\
R = 100  & S = 14 \\
& \\
C_{0} = 0.034  & \rho = 1.13 \\
& \\
k = 0.069662  & g=9.80665
\end{array}
$$

The lift coefficient is bounded

$$
0 \leq C_{L} \leq 1.4
$$

And the following boundary conditions are imposed:

$$
\begin{array}{cc}
x(0) = 0  & x(t_{f}): \text{free} \\
& \\
y(0) = 1000  & y(t_{f}) = 900 \\
& \\
v_{x}(0) = 3.227567500  & v_{x}(t_{f}) = 3.227567500 \\
& \\
v_{y}(0) = −1.2875005200  & v_{y}(t_{f}) = −1.2875005200
\end{array}
$$

The initial guess was computed using linear interpolation between the boundary conditions, with $x(t_{f}) = 1250$, and $C_{L}(0) = C_{L}(t_{f}) = 1$.

Using `JuMP.jl` easily allows for formatting this much more complicated example into code very similar to the simpler example.

```julia:glider-init
glider_model = Model(Ipopt.Optimizer)
set_silent(glider_model)
```

Values:

```julia:glider-vals
u_M = 2.5
m = 100
R = 100
S = 14
C_0 = 0.034
ρ = 1.13
k = 0.069662
g = 9.080665

n_glider = 200
```

Defining state and control variables:

```julia:glider-vars
@variables(glider_model, begin
    # Time step
    Δt ≥ 0, (start = 1 / n_glider)

    # state variables
    x[1:n_glider] ≥ 0
    vx[1:n_glider] ≥ 0
    y[1:n_glider] ≥ 0
    vy[1:n_glider]

    # control variable
    0 ≤ C_L[1:n_glider] ≤ 1.4
end)
```

Setting boundary conditions and initial guesses:

```julia:glider-ic
fix(x[1], 0; force=true)

fix(y[1], 1000; force=true)
fix(y[n_glider], 900; force=true)

fix(vx[1], 13.227567500; force=true)
fix(vx[n_glider], 13.227567500; force=true)

fix(vy[1], -1.2875005200; force=true)
fix(vy[n_glider], -1.2875005200; force=true)

set_start_value(x[n_glider], 1250)
set_start_value(C_L[1], 1)
set_start_value(C_L[n_glider], 1)
```

Defining expressions:

```julia:glider-exp
@NLexpressions(
    glider_model,
    begin
        C_D[j=1:n_glider], C_0 + k * C_L[j]^2

        X[j=1:n_glider], (x[j]/R - 2.5)^2

        u_a[j=1:n_glider], u_M*(1 - X[j])*exp(-X[j])

        V_y[j=1:n_glider], vy[j] - u_a[j]

        v_r[j=1:n_glider], sqrt(vx[j]^2 + V_y[j]^2)

        L[j=1:n_glider], 0.5*C_L[j]*ρ*S*v_r[j]^2

        D[j=1:n_glider], 0.5*C_D[j] * ρ * S * v_r[j]^2

        sin_η[j=1:n_glider], V_y[j]/v_r[j]

        cos_η[j=1:n_glider], vx[j]/v_r[j]
    end
)
```

Defining system dynamics:

```julia:glider-dynamics
for j in 2:n_glider
    @NLconstraint(glider_model, x[j] == x[j-1] + 0.5*Δt*(vx[j] + vx[j-1]))
    @NLconstraint(glider_model, y[j] == y[j-1] + 0.5*Δt*(vy[j] + vy[j-1]))
    @NLconstraint(glider_model,
        vx[j] == vx[j-1] + 0.5*Δt*(
            (1/m)*(-L[j] * sin_η[j] - D[j] * cos_η[j]) +
            (1/m)*(-L[j-1] * sin_η[j-1] - D[j-1] * cos_η[j-1])
        )
    )
    @NLconstraint(glider_model,
        vy[j] == vy[j-1] + 0.5*Δt*(
            (1/m)*(L[j] * cos_η[j] - D[j] * sin_η[j] - m*g) +
            (1/m)*(L[j-1] * cos_η[j-1] - D[j-1] * sin_η[j-1] - m*g)
        )
    )
end
```

Setting objective and optimizing:

```julia:glider-opt
@objective(glider_model, Max, x[n_glider])

optimize!(glider_model)
solution_summary(glider_model)
```

\show{glider-opt}

Visualizing the state variables over the time period:

```julia:glider-sol
function plot_opt_variable(fig_ax, y, ylabel)
    ax = Axis(fig_ax, xlabel="Time (s)", ylabel=ylabel)
    lines!(ax, (1:n_glider) * value.(Δt), value.(y)[:])
    return ax
end

fig2 = Figure(resolution=(1000,500))

ax21 = plot_opt_variable(fig2[1,1], x, "Horizontal Distance (m)")
ax22 = plot_opt_variable(fig2[1,2], y, "Altitude (m)")
ax23 = plot_opt_variable(fig2[2,1], vx, "Horizontal Velocity (m/s)")
ax24 = plot_opt_variable(fig2[2,2], vy, "Vertical Velocity (m/s)")

fig2
save("assets/posts/optimal-control-jump/code/glider-optim.svg", fig2) #hide
```

@@im-100
\fig{glider-optim}
@@

We can also plot the control action $u(t) = C_L$ over time:

```julia:glider-control
fig3 = Figure(resolution=(800,400))
ax31 = plot_opt_variable(fig3[1,1], C_L, L"C_L")

fig3
save("assets/posts/optimal-control-jump/code/glider-control.svg", fig3) #hide
```

@@im-75
\fig{glider-control}
@@

As can be seen, the problem setup for this example is quite similar to the previous example. It has many more variables and expressions involved, but the fundamental problem definition is quite similar. This is why I enjoy using `JuMP.jl` so much, it's great for both simple and complex optimization problems.

## Wrapping Up

Thanks for reading! I hope this post was insightful and inspired you to check out using `JuMP.jl` for optimal control work. I will continue to learn the theory behind optimal control, so expect more posts on this topic soon. Until next time.
