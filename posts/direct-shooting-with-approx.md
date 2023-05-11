@def title = "Direct Shooting Method with Approximated Jacobian Matrices"
@def published = "May 6th, 2023"
@def tags = ["Programming", "Julia", "Blogging", "Optimal Control", "Numerical Methods"]

<!-- @def reeval = true -->

# Direct Shooting Method with Approximated Jacobian Matrices

_By Michal Jagodzinski - May 6th, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/yvwd-CofSqA)
@@

@@img-caption
Photo by [Kym MacKinnon](https://unsplash.com/photos/yvwd-CofSqA)
@@

Alright, I know the title of this post is quite a mouthful, but it's the best I can do. We're building upon my previous optimal control post, [The Direct Shooting Method](https://michaszj.github.io/starcoffee/posts/the-direct-shooting-method/). Looking back on that post I unfortunately did a poor job describing the code. In this post, I'll go more into the code from that post, and define a more generalized method to solving the target hitting problem using direct shooting.

## Previous Example: Target Hitting with Automatic Differentiation

[In the previous post on the direct shooting method](https://michaszj.github.io/starcoffee/posts/the-direct-shooting-method/), I covered how to solve the target hitting problem using the [multivariable Newton's Method](https://en.wikipedia.org/wiki/Newton%27s_method#Systems_of_equations). Newton's Method involves calculating Jacobian matrices, which I did using automatic differentiation (see [here](https://michaszj.github.io/starcoffee/posts/the-direct-shooting-method/#mathematical_background) if you need a refresher on the math). I apologize for failing to mention this explicitly, as calculating the Jacobian matrix is an important step in this process.

In that post, I used `Zygote.jl` as the automatic differentiation library, and calculated the Jacobian matrices using:

```julia
F(u) = [
    (u[1] * 2*u[2]/g) - target[1],
    0
]

un = [ẋ₀, ẏ₀]

DF = jacobian(F, un)[1]
```

Here, we are calculating the Jacobian using automatic differentiation, passing in the function that defines the $\mathbf F$ matrix and the initial conditions. Here, `F()` is a function of the initial $x$ and $y$ velocities of the projectile.

## Approximating the Jacobian Matrix with Finite Differences

Now let's go over approximating the numerical value of the Jacobian matrix. This is a more general method because we often only have the dynamics of a system, not the kinematics. When we only have the dynamics of a system, the previous method using automatic differentiation does not work.

Just for reference, the Jacobian of the $\mathbf F$ matrix is defined as:

$$
\mathbf{J} = \begin{bmatrix}
\dfrac{ \partial F_{1} }{ \partial a_{1} }  & \dots  & \dfrac{ \partial F_{1} }{ \partial a_{n} }  \\
\vdots  & \ddots  & \vdots \\
\dfrac{ \partial F_{m} }{ \partial a_{1} }  & \dots  & \dfrac{ \partial F_{m} }{ \partial a_{n} }
\end{bmatrix}
$$

Automatic differentiation gives us essentially the exact numerical value of the Jacobian matrix (minus errors due to floating-point values). Without the kinematic equations, we can instead use finite differences to approximate the terms of the Jacobian:

$$
\frac{\partial F_m}{\partial a_n} \approx \frac{F(a_{n,2}) - F(a_{n,1})}{a_{n,2} - a_{n,1}}
$$

For this problem, hitting a target with a projectile, the general $\mathbf{F}$ matrix is defined as:

$$
\mathbf{F} = \begin{bmatrix}
x(t_{t}; \dot{x}_{0}) - x_{t}  \\
y(t_{f}; \dot{y}_{0}) - y_{t}
\end{bmatrix}
$$

Due to the problem we are covering, we can simplify this to:

$$
\mathbf{F} = \begin{bmatrix}
x(t_{t}; \dot{x}_{0}) - x_{t}  \\
0
\end{bmatrix}
$$

We can do this since the final $y$ value of the projectile is always zero, it always hits the ground eventually, and we are assuming the target is always on the ground as well. Now we can approximate the Jacobian of this matrix as:

$$
\mathbf{J} = \begin{bmatrix} \dfrac{\partial F_1}{\partial \dot x_0} & \dfrac{\partial F_1}{\partial \dot y_0} \\ & \\ 0 & 0 \end{bmatrix} \approx \begin{bmatrix} \dfrac{F_{1,2} - F_{1,1}}{\dot x_{0,2} - \dot x_{0,1}} & \dfrac{F_{1,2} - F_{1,1}}{\dot y_{0,2} - \dot y_{0,1}} \\ & \\ 0 & 0 \end{bmatrix}
$$

Where

$$
F_{1,1} = x(t_{t}; \dot{x}_{0,1}) - x_{t} \quad \quad F_{1,2} = x(t_{t}; \dot{x}_{0,2}) - x_{t}
$$

To demonstrate using this method, let's use a more complex version of the previous example. We'll still try to hit a target with a projectile, but now we'll also introduce air resistance. The dynamics of the projectile are now defined by the following differential equations:

$$
\begin{align*}

\ddot x &= - \frac{g}{v_t} \dot x \\

\ddot y &= -g - \frac{g}{v_t} \dot y

\end{align*}
$$

Where $v_t$ is the terminal velocity, defined as:

$$
v_t = \frac{mg}{c}
$$

Where $m$ is the projectile mass and $c$ is the drag coefficient. These differential equations do have an analytical solution, so we can still use the previous method to solve this problem. However, for demonstration of the general technique I won't cover that.

Let's get into some code now. For modeling and numerically solving the system of differential equations we'll be using `ModelingToolkit.jl` and `OrdinaryDiffEq.jl`. Importing the required libraries:

```julia:imports
using CairoMakie, AlgebraOfGraphics
using ModelingToolkit, OrdinaryDiffEq, LinearAlgebra
set_aog_theme!()
```

Defining constants and system variables:

```julia:vars
const g = 9.80665
const m = 5.0
const c = 0.25
const vt = m*g / c

@parameters t
D = Differential(t)

@variables x(t) ẋ(t) y(t) ẏ(t)
```

Defining the `ODESystem`:

```julia:sys
sys = ODESystem(
    [
        D(x) ~ ẋ,
        D(ẋ) ~ -(g/vt)*ẋ,
        D(y) ~ ẏ,
        D(ẏ) ~ -g - (g/vt)*ẏ
    ],
    t,
    name = :proj_drag_system
)
```

When simulating this system, the simulation will run even when the $y$ value becomes negative, i.e., the projectile falls through and continues on below the ground. We obviously don't want this, so we'll create a callback to interrupt the simulation when $y=0$ (see [Event Handling and Callback Functions](https://docs.sciml.ai/DiffEqDocs/stable/features/callback_functions/) documentation for more information). The callback is defined with:

```julia:callback
ground_condition(u, t, integrator) = u[3]
ground_affect!(integrator) = terminate!(integrator)
ground_cb = ContinuousCallback(ground_condition, ground_affect!)
```

The continuous callback works by triggering when the condition function is equal to zero, in this case the `ground_condition` function. I set the function equal to the $y$ value, thus it will trigger when $y$ becomes zero. This causes the simulation to terminate, as at that point the projectile has impacted the ground.

Now we need to set up our initial simulations. For this method, we need to start with two separate initial guesses.

```julia:init
target = [200, 0]

ẋ1 = 40.0
ẋ2 = 41.0

ẏ1 = 25.0
ẏ2 = 26.0

function simulate_projectile(ẋ0, ẏ0; tspan=[0.0, 15.0])
    u0 = [
        x => 0.0,
        ẋ => ẋ0,
        y => 0.0,
        ẏ => ẏ0
    ]

    prob = ODEProblem(sys, u0, tspan, jac=true)

    return solve(prob, Tsit5(), callback=ground_cb)
end

sol1 = simulate_projectile(ẋ1, ẏ1)
sol2 = simulate_projectile(ẋ2, ẏ2)

function interp_sol(
    solution::ODESolution,
    vars::Vector{Num},
    times::Union{StepRangeLen, Vector}
)

    sol_interp = solution(times)
    return [sol_interp[var] for var in vars]
end

fig1 = Figure(resolution=(1000,300))
ax1 = Axis(fig1[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax1, [target[1]], [target[2]], label="Target")

times=0.0:0.1:15.0
lines!(ax1, interp_sol(sol1, [x,y], times)..., label="Trajectory 1")
lines!(ax1, interp_sol(sol2, [x,y], times)..., label="Trajectory 2")

axislegend(ax1, position=:lt)
save("assets/posts/direct-shooting-with-approx/code/init.svg", fig1) #hide
```

@@im-100
\fig{init}
@@

With the initial guesses defined, we can now calculate the next guess by using Newton's Method, and approximating the terms of the Jacobian using finite differences:

```julia:guess
F1 = [sol1[x, end], sol1[y, end]] .- target
F2 = [sol2[x, end], sol2[y, end]] .- target

dF = [
    (F2[1] - F1[1])/(ẋ2 - ẋ1) (F2[1] - F1[1])/(ẏ2 - ẏ1)
    0 0
]

ẋ3_sim, ẏ3_sim = [ẋ2, ẏ2] .- pinv(dF)*F2
```

\show{guess}

These two values are our next guesses for the required initial velocity of the projectile. These values should provide a more accurate result. However, we'll probably still need to iterate multiple times to get to a decently accurate result. Also note the use of `pinv()` instead of the `inv()` function. An error occurs when calculating the inverse of the `dF` matrix, I think the inverse is technically undefined for it. In any case, calculating the pseudoinverse works just fine.

Now we can set up the loop to repeat the process above to continuously change the initial velocities to hit the target:

```julia:loop
fig2 = Figure(resolution=(1000,300))
    ax2 = Axis(fig2[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

    scatter!(ax2, [target[1]], [target[2]], label="Target")

    lines!(ax2, interp_sol(sol1, [x,y], times)..., label="Trajectory 1")
    lines!(ax2, interp_sol(sol2, [x,y], times)..., label="Trajectory 2")

    errors = [
    abs(sol1[x, end] - target[1]),
    abs(sol2[x, end] - target[1])
]

ẋ2_sim = copy(ẋ2)
ẏ2_sim = copy(ẏ2)

n_iters = 10

for i in 1:n_iters
    sol3 = simulate_projectile(ẋ3_sim, ẏ3_sim)

    global F1 = copy(F2)
    global F2 = [sol3[x, end], sol3[y, end]] .- target

    global dF = [
        (F2[1] - F1[1])/(ẋ3_sim - ẋ2_sim) (F2[1] - F1[1])/(ẏ3_sim - ẏ2_sim)
        0 0
    ]

    global ẋ2_sim = copy(ẋ3_sim)
    global ẏ2_sim = copy(ẏ3_sim)

    u̇ = [ẋ2_sim, ẏ2_sim] .- pinv(dF)*F2

    global ẋ3_sim = u̇[1]
    global ẏ3_sim = u̇[2]

    if i < n_iters
        lines!(
            ax2, interp_sol(sol3, [x,y], times)...,
            linestyle=:dash, color = (:red, 0.2)
        )
    else
        lines!(
            ax2, interp_sol(sol3, [x,y], times)...,
            color=:red, label="Trajectory $(n_iters+2)"
        )
    end

    push!(errors, abs(sol3[x, end] - target[1]))
end

axislegend(ax2, position=:lt)
fig2
save("assets/posts/direct-shooting-with-approx/code/results.svg", fig2) #hide
```

@@im-100
\fig{results}
@@

```julia:errors
fig3=Figure()

ax3=Axis(
    fig3[1,1],
    xlabel="Iteration", ylabel="Error",
    yscale=log10, yminorticksvisible = true,
    yminorgridvisible = true, yminorticks = IntervalsBetween(9),
    xticks=1:2:n_iters+2
)

lines!(ax3, errors)

fig3
save("assets/posts/direct-shooting-with-approx/code/errors.svg", fig3) #hide
```

@@im-75
\fig{errors}
@@

As can be seen, through multiple iterations, we successfully get closer and closer to hitting the target by using the direct shooting method with approximate Jacobian matrix values.

## Hitting a Target in Mid-Air

Now for a slightly more complicated example. Up until now, we have been assuming the target is on the ground. Let's now consider the case where a target is in an arbitrary position.

First we need to redefine the Jacobian matrix, as it was defined with the assumption that the final $y$ value of the projectile is always zero. For the arbitrary case, the Jacobian can be approximated as:

$$
\mathbf{J} = \begin{bmatrix} \dfrac{\partial F_1}{\partial \dot x_0} & \dfrac{\partial F_1}{\partial \dot y_0} \\ & \\ \dfrac{\partial F_2}{\partial \dot x_0} & \dfrac{\partial F_2}{\partial \dot y_0} \end{bmatrix} \approx \begin{bmatrix} \dfrac{F_{1,2} - F_{1,1}}{\dot x_{0,2} - \dot x_{0,1}} & \dfrac{F_{1,2} - F_{1,1}}{\dot y_{0,2} - \dot y_{0,1}} \\  & \\ \dfrac{F_{2,2} - F_{2,1}}{\dot x_{0,2} - \dot x_{0,1}} & \dfrac{F_{2,2} - F_{2,1}}{\dot y_{0,2} - \dot y_{0,1}} \end{bmatrix}
$$

In practice, this situation is not much more complicated, we just need to ensure we are changing the definition of the Jacobian properly, the rest of our code written previously will work perfectly fine. Another change we should make is to the callback function. For this case, I not only want the simulation to stop when the projectile hits the ground, but also if the projectile reaches the $x$ position of the target. We can define the new callback as:

```julia:callback2
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
```

The same logic applies when using `VectorContinuousCallback` as with `ContinuousCallback`, we define the conditions so that the callback is triggered when the condition function is equal to zero. In this case, we just have to define multiple conditions.

Let's choose a new target position at $(180,20)$. We can use the previous two guesses to calculate the initial conditions for this case as well.

```julia:guess2
target2 = [180, 20]

sol12 = simulate_projectile2(ẋ1, ẏ1)
sol22 = simulate_projectile2(ẋ2, ẏ2)

fig4 = Figure(resolution=(1000,300))
ax4 = Axis(fig4[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax4, [target2[1]], [target2[2]], label="Target")

lines!(ax4, interp_sol(sol12, [x,y], times)..., label="Trajectory 1")
lines!(ax4, interp_sol(sol22, [x,y], times)..., label="Trajectory 2")

axislegend(ax4, position=:lt)
save("assets/posts/direct-shooting-with-approx/code/guess2.svg", fig4) #hide
```

@@im-100
\fig{guess2}
@@

Once again, we define the $\mathbf F$ matrices and the approximated Jacobian:

```julia:init2
F12 = [sol12[x, end], sol12[y, end]] .- target2
F22 = [sol22[x, end], sol22[y, end]] .- target2

dF2 = [
    (F22[1] - F12[1])/(ẋ2 - ẋ1) (F22[1] - F12[1])/(ẏ2 - ẏ1)
    (F22[2] - F12[2])/(ẋ2 - ẋ1) (F22[2] - F12[2])/(ẏ2 - ẏ1)
]

ẋ3_sim2, ẏ3_sim2 = [ẋ2, ẏ2] .- pinv(dF2)*F22
```

\show{init2}

As can be seen, we just need to include the extra terms for the `dF` variable to make it compatible for this case. Let's now do the iteration loop:

```julia:loop2
fig5 = Figure(resolution=(1000,300))
ax5 = Axis(fig5[1,1], xlabel="x (m)", ylabel="y (m)", aspect = DataAspect())

scatter!(ax5, [target2[1]], [target2[2]], label="Target")

lines!(ax5, interp_sol(sol12, [x,y], times)..., label="Trajectory 1")
lines!(ax5, interp_sol(sol22, [x,y], times)..., label="Trajectory 2")

ẋ2_sim2 = copy(ẋ2)
ẏ2_sim2 = copy(ẏ2)

errors2 = [
    sqrt((sol12[x, end] - target2[1])^2 + (sol12[y, end] - target2[2])^2),
    sqrt((sol22[x, end] - target2[1])^2 + (sol22[y, end] - target2[2])^2)
]

n_iters2 = 10

for i in 1:n_iters2
    sol32 = simulate_projectile2(ẋ3_sim2, ẏ3_sim2)

    global F12 = copy(F22)
    global F22 = [sol32[x, end], sol32[y, end]] .- target2

    global dF2 = [
        (F22[1] - F12[1])/(ẋ3_sim2 - ẋ2_sim2) (F22[1] - F12[1])/(ẏ3_sim2 - ẏ2_sim2)
        (F22[2] - F12[2])/(ẋ3_sim2 - ẋ2_sim2) (F22[2] - F12[2])/(ẏ3_sim2 - ẏ2_sim2)
    ]

    global ẋ2_sim2 = copy(ẋ3_sim2)
    global ẏ2_sim2 = copy(ẏ3_sim2)

    u̇ = [ẋ2_sim2, ẏ2_sim2] .- pinv(dF2)*F22

    global ẋ3_sim2 = u̇[1]
    global ẏ3_sim2 = u̇[2]

    if i < n_iters
        lines!(
            ax5, interp_sol(sol32, [x,y], times)...,
            linestyle=:dash, color = (:red, 0.2)
        )
    else
        lines!(
            ax5, interp_sol(sol32, [x,y], times)...,
            color=:red, label="Trajectory $(n_iters+2)"
        )
    end
    push!(errors2, sqrt((sol32[x, end] - target2[1])^2 + (sol32[y, end] - target2[2])^2))
end

axislegend(ax5, position=:lt)
fig5
save("assets/posts/direct-shooting-with-approx/code/loop2.svg", fig5) #hide
```

@@im-100
\fig{loop2}
@@

```julia:errors2
fig6=Figure()

ax6=Axis(
    fig6[1,1],
    xlabel="Iteration", ylabel="Error",
    yscale=log10, yminorticksvisible = true,
    yminorgridvisible = true, yminorticks = IntervalsBetween(9),
    xticks=1:2:n_iters+2
)

lines!(ax6, errors2)

fig6
save("assets/posts/direct-shooting-with-approx/code/errors2.svg", fig6) #hide
```

@@im-75
\fig{errors2}
@@

As can be seen, by using a different callback function and changing the definition of the Jacobian matrix, we implemented a more generalized direct shooting method to solve the target hitting problem.

## Conclusion

Thanks for reading! I Hope I clarified things a bit as the previous post on this topic was quite rough. I want to continue learning and writing about optimal control more, so expect more posts on this topic soon. I am taking a bit of a break from working on [SAT](https://michaszj.github.io/starcoffee/posts/satellite-analysis-toolkit/), I want to explore some other topics. So hopefully soon there should be an interesting variety of work going up on Star Coffee. Until next time.
