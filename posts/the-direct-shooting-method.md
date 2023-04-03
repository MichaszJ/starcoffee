# The Direct Shooting Method

@def reeval = true

_April 3rd, 2023_
@@im-100
![](https://source.unsplash.com/a2PfxRXCYQM)
@@

<!-- prettier-ignore -->
~~~
<p style="color:#808080; text-align:center; font-size: medium;">Photo by <a href="https://unsplash.com/photos/a2PfxRXCYQM">Maxence Pira</a></p>
~~~

Following graduation, I have been interested in learning a variety of different topics, one being [optimal control](https://en.wikipedia.org/wiki/Optimal_control). It's a pretty complex topic that I've been struggling to understand for a while, especially with being able to apply the theoretical concepts I've been reading about. At this point however I feel ready to cover some simple ideas in optimal control, the first being the direct shooting method.

## Mathematical Background

The direct shooting method is a way to solve a [boundary value problem](https://en.wikipedia.org/wiki/Boundary_value_problem) by converting it into an [initial value problem](https://en.wikipedia.org/wiki/Initial_value_problem). The solution to the problem is equal to the root(s) of the following equation:

$$
F(a) = y(t_{1}; a) - y_{1}
$$

Where $a$ is the initial condition and $y_1$ is the target value. If the notation is unclear, you can think of $ y(t\_{1}; a)$ as the value of $y$ at time $t_f$ given initial condition $a$. See the Wikipedia article linked above if you'd like a more rigorous explanation.

There are various numerical methods to find roots, in this case I went with Newton's method. This is an iterative method, starting with an initial guess of the root $a_n$. The method converges upon a root with the following iterative step:

$$
a_{n+1} = a_{n} - \frac{F(a_{n})}{F^\prime(a_{n})}
$$

This works in the case of single variables, however often we want to find the roots of functions with multiple variables. For this, we can use the following form of Newton's method:

$$
\mathbf{a}_{n+1} = \mathbf{a}_{n} - \mathbf{J}^{-1} F(\mathbf{a}_{n})
$$

Where $\mathbf{J}$ is the Jacobian matrix of $f(\mathbf{x}_{n})$, which is defined as:

$$
\mathbf{J} = \begin{bmatrix}
\dfrac{ \partial F_{1} }{ \partial a_{1} }  & \dots  & \dfrac{ \partial F_{1} }{ \partial a_{n} }  \\
\vdots  & \ddots  & \vdots \\
\dfrac{ \partial F_{m} }{ \partial a_{1} }  & \dots  & \dfrac{ \partial F_{m} }{ \partial a_{n} }
\end{bmatrix}
$$

Now, with each iteration we come closer to the vector of initial values that solve the boundary value problem.

## Hitting a Target

To demonstrate using the direct shooting method, I will show how to use it to calculate the required velocity of a projectile to hit an arbitrary target. Assuming no drag, with the starting position of $(0,0)$, the kinematics for the projectile are:

$$
\begin{align*}
x(t) &= \dot{x}_{0}t \\
y(t) &= \dot{y}_{0}t - \frac{1}{2}gt^2
\end{align*}
$$

Let's say we have a target at $(200,0)$. No we need to find the initial velocities $\dot{x}_{0}, \dot{y}_{0}$ that are required to hit the target.

First we need to calculate the time of flight of the projectile. $\dot{x}_{0}$ does not affect the time of flight but $\dot{y}_{0}$ does:

$$
\begin{align*}
y(t_{f}) = \dot{y}_{0} t_{f} - \frac{1}{2} gt_{f}^2 &= 0 \\
\dot{y}_{0} &= \frac{1}{2} gt_{f}  \\
t_{f} &= 2 \frac{\dot{y}_{0}}{g}
\end{align*}
$$

Next we can define our $\mathbf{F}$ matrix based on the time of flight. This is a multivariable case, hence why I mentioned the multivariable form of Newton's method earlier.

$$
\mathbf{F} = \begin{bmatrix}
x(t_{t}; \dot{x}_{0}) - x_{t}  \\
y(t_{f}; \dot{y}_{0}) - y_{t}
\end{bmatrix} = \begin{bmatrix}
2 \dfrac{\dot{x}_{0} \dot{y}_{0}}{g} - 200  \\
0
\end{bmatrix}
$$

For this example, $y(t_{f}; \dot{y}_{0}) - y_{t}$ simplifies to zero since no matter where the projectile hits the ground, its height off the ground is zero, plus the target's $y$ position is also zero. Now we can implement this in code.

Importing required libraries:

```julia:imports
import Pkg; Pkg.add(["Plots", "Zygote"]) # hide
using Plots, Zygote, LinearAlgebra
```

Defining constants and initial conditions:

```julia:consts
g = 9.80665
ẋ₀ = 15.0
ẏ₀ = 15.0
target = [200, 0]
```

Defining the $\mathbf{F}$ matrix:

```julia:F
F(u) = [
    (u[1] * 2*u[2]/g) - target[1],
    0
]
```

Defining the equations of motion:

```julia:eqnsmotion
xt(t, ẋ) = ẋ * t
yt(t, ẏ) = ẏ * t - 0.5*g*t^2
```

Plotting initial trajectory and iteration loop:

```julia:main
p1 = scatter(
    [target[1]], [target[2]],
    label="Target",
    dpi=300,
    xlabel="x (m)",
    ylabel="y (m)",
    aspect_ratio=:equal,
    margin=5Plots.PlotMeasures.mm
)

impact_time = 2*ẏ₀/g
times = 0.0:0.01:impact_time
plot!(p1, xt.(times, ẋ₀), yt.(times, ẏ₀), label="Trajectory 1")

un = [ẋ₀, ẏ₀]
errors = [abs(target[1] - xt(impact_time, ẋ₀))]

for i in 1:6
    F_mat = F(un)
    DF = jacobian(F, un)[1]

    global un = un - pinv(DF)*F_mat


    global impact_time = 2*un[2]/g
    global times = 0.0:0.01:impact_time

    plot!(xt.(times, un[1]), yt.(times, un[2]), label="Trajectory $(i+1)")

    push!(errors, abs(target[1] - xt(impact_time, un[1])))
end

p1
savefig(joinpath(@OUTPUT, "shooting-trajectories.svg")) # hide
```

@@im-75
\fig{shooting-trajectories}
@@

```julia:errors
scatter(
    errors,
    yaxis=:log, minorgrid=true,
    label="", xlabel="Iteration", ylabel="Error",
    marker=:xcross
)
savefig(joinpath(@OUTPUT, "errors.svg")) # hide
```

@@im-75
\fig{errors}
@@

As can be seen, using the direct shooting method quickly converges upon the required initial velocity to hit the target. For this example, the velocity is:

```julia:answer
round.(un, digits=4)
```

\show{answer}

## Conclusion

In conclusion, using the direct shooting method and Newton's method allows us to numerically calculate the initial conditions required to solve some boundary value problems. The example I covered was pretty simple, and I plan to do some more complex problems in the future. Specifically, I want to cover the projectile example but with added drag, and solving the problem solely using the dynamics of the system, instead of relying on the kinematic equations.

Hope you enjoyed reading and learned something. I'll definitely be writing more about optimal control the more I learn about it, as I find it a very fascinating albeit hard field. Until next time.
