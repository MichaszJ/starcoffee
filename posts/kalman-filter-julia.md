@def title = "Implementing a Linear Kalman Filter in Julia"
@def subtitle = "Implementing the linear Kalman filter for state estimation in Julia"
@def published = "September 3rd, 2023"
@def author = "Michal Jagodzinski"
@def tags = ["Blogging", "Programming", "Julia", "Aerospace"]

@def mintoclevel=1

@def reeval = true

{{ generate_title "kalman-filter-julia.md" }}

@@im-60
![](https://source.unsplash.com/UM6icC4s4gQ)
@@

@@img-caption
Photo by [Daniel J. Schwarz](https://unsplash.com/photos/UM6icC4s4gQ)
@@


\tableofcontents

# Introduction to the Kalman Filter

## State Estimation

As implied by the term, [state estimation](https://www.nasa.gov/centers/ames/research/technology-onepagers/state-estimation.html) involves using models and data to estimate the state of a system. State usually involves useful quantities of systems such as position, velocity, attitude, etc. 

The linear Kalman filter and its other forms are very commonly used in the aerospace field for state estimation applications. If you're interested in the aerospace GN&C field like me, understanding state estimation and Kalman filters is essential.

## The Kalman Filter Algorithm

I am not going to go in depth on the theory, math, derivation, etc. behind the Kalman filter. If you'd like to learn more in detail, I highly recommend checking out [Kalman and Bayesian Filters in Python](https://github.com/rlabbe/Kalman-and-Bayesian-Filters-in-Python), a great free book that delves into derivation and theory of Kalman filters.

The Kalman filter works by representing the state(s) of our system with [Gaussian distributions](https://en.wikipedia.org/wiki/Normal_distribution). A Gaussian distribution is defined by two parameters, a mean, and a variance (or standard deviation). Essentially, we are defining each state of a system with some level of uncertainty.

<!-- ```julia:guassian
#hideall
gaussian_fig = Figure()
gaussian_ax = Axis(gaussian_fig[1,1])

x_dist = -5:0.01:5
dists = [[0.0, 1.0], [0.0, 0.5], [0.0, 2.0]]

for dist in dists
    gaussian = Normal(dist...)
    gaussian_pdf = pdf.(gaussian, x_dist)

    lines!(
        gaussian_ax, x_dist, gaussian_pdf; 
        label="μ=$(dist[1]) σ=$(dist[2])"
    )
end

axislegend(gaussian_ax)

gaussian_fig
save("assets/posts/kalman-filter-julia/code/gaussian_fig.svg", gaussian_fig)
``` -->

@@im-100
\fig{gaussian_fig}
@@

@@img-caption
Some probability density functions of Gaussian distributions with varying means $\mu$ and standard deviations $\sigma$.
@@

The Kalman filter algorithm has two distinct steps, prediction and correction. The filter first predicts the state of the system after a discrete timestep $\Delta t$. It then uses a measurement of the system at that time to correct that prediction and give a more accurate (accurate meaning less variance of the Gaussian) prediction of the true state of the system.

@@im-100
\fig{kf-fig1.svg}
@@

Obviously every mathematical model used to generate the prediction and the sensors used to measure the state(s) of the system contain noise. Noise is a simple fact of life. However, by combining these two distinct sources of information, the Kalman filter provides a much more accurate estimate of the state than each individual data point. We can think of the predictions $\bar x$ and measurements $z$ as areas where the true state of the system can exist within. Using these two values we can assume that the true state must lie somewhere between these two values:

@@im-50
\fig{kf-fig2.svg}
@@

As you can clearly see, the true trajectory must reside within the intersection of $\bar x$ and $z$, and that this intersection is a much smaller possible area than either $\bar x$ or $z$ on their own. Here lies the power of the Kalman filter, combining information about the state in the prediction step and using measurements to update that prediction results in a significantly more accurate estimate of the true value of the state.

<!-- ```julia:guassian2
#hideall
gaussian_fig2 = Figure()
gaussian_ax2 = Axis(gaussian_fig2[1,1])

# x_dist = -5:0.01:5
# dists2 = [[-3, 1.0], [3, 1.0], [0.0, 0.5]]

# for dist in dists2
#     gaussian = Normal(dist...)
#     gaussian_pdf = pdf.(gaussian, x_dist)

#     lines!(
#         gaussian_ax2, x_dist, gaussian_pdf; 
#         label="μ=$(dist[1]) σ=$(dist[2])"
#     )
# end

lines!(
    gaussian_ax2,
    x_dist, pdf.(Normal(-3, 1.0), x_dist),
    # label="Estimate"
)

lines!(
    gaussian_ax2,
    x_dist, pdf.(Normal(3, 1.0), x_dist),
    # label="Measurement"
)

lines!(
    gaussian_ax2,
    x_dist, pdf.(Normal(0, 0.5), x_dist),
    # label="Update"
)

text!(-3, 0.42, text="Prediction", align=(:center, :bottom))
text!(3, 0.42, text="Measurement", align=(:center, :bottom))
text!(0, 0.82, text="Update", align=(:center, :bottom))

save("assets/posts/kalman-filter-julia/code/gaussian_fig2.svg", gaussian_fig2)
``` -->

@@im-100
\fig{gaussian_fig2}
@@

@@img-caption
Combining the prediction and measurement Gaussians provides an updated estimate of the state with lower variances/higher accuracy.
@@

Assuming a general multivariate system, starting with the state mean $\mathbf x$ and covariance matrix $\mathbf P$, the prediction step is defined as:

$$ \begin{aligned} \bar{\textbf x} &= \textbf{F} \textbf x + \textbf B \textbf u \\ \bar{\textbf P} &= \textbf{FPF}^\intercal + \textbf Q \end{aligned} $$

Where $\textbf x$, $\textbf P$ are the state mean and [covariance matrix](https://en.wikipedia.org/wiki/Covariance_matrix), $\textbf F$ is the state transition matrix, $\textbf Q$ is the process covariance, and $\textbf B$, $\textbf u$ are the control inputs to the system (if control inputs are applied).

Next, given a vector of measurements $\mathbf z$, the update step is defined as:

$$ \begin{aligned} \textbf y &= \textbf z - \textbf H \bar{\textbf x} \\ \textbf K &= \bar{\textbf P} \textbf H^\intercal (\textbf H \bar{\textbf P} \textbf H^\intercal + \textbf R)^{-1} \\ \textbf x &= \bar{\textbf x} + \textbf K \textbf y \\ \textbf P &= (\textbf I - \textbf K \textbf H) \bar{\textbf P} \end{aligned} $$

Where $\textbf H$ is the measurement matrix, $\mathbf z$, $\textbf R$ are the measurement mean and noise covariance, and $\textbf y$, $\textbf K$ are the residual and Kalman gain.

# Kalman Filter Implementation

First let's import some required libraries (optionally I also defined some custom plot styles):

```julia:imports
using Random, LinearAlgebra, Distributions, CairoMakie

# custom plot styling
CairoMakie.activate!(type = "svg")
set_theme!(theme_minimal())

gray_val = 150
gray_col = Makie.RGB(gray_val/255, gray_val/255, gray_val/255)

update_theme!(
    fonts = (; regular = "JuliaMono-Light", bold = "JuliaMono-Light"),
    Axis = (
        leftspinevisible = true,
        rightspinevisible = false,
        bottomspinevisible = true,
        topspinevisible = false,
        leftspinecolor = gray_col,
        bottomspinecolor = gray_col,
        xtickcolor = gray_col,
        xticksvisible = true,
        xminorticksvisible = true,
        xminortickcolor = gray_col,
        ytickcolor = gray_col,
        yticksvisible = true,
        yminorticksvisible = true,
        yminortickcolor = gray_col,
        xminortickalign = 1.0,
        xtickalign = 1.0,
        yminortickalign = 1.0,
        ytickalign = 1.0,
        yticksize=7, xticksize=7,
        yminorticksize=5, xminorticksize=5,
        xticklabelsize=13.0f0, yticklabelsize=13.0f0
    )
)
```

Let's start by creating two `struct`s to keep track of our system state and Kalman filter:

```julia:filter-structs
mutable struct State
    mean::AbstractVector
    cov::AbstractMatrix
end

mutable struct KalmanFilter
    state::State
    state_transition::AbstractMatrix
    process_cov::AbstractMatrix
    measurement_function::AbstractMatrix
    measurement_noise_cov::AbstractArray
end
```

Next let's define a function to implement the prediction step of the Kalman filter:
```julia:filter-predict
function kalman_predict!(kf::KalmanFilter)
    kf.state.mean = kf.state_transition * kf.state.mean
    kf.state.cov = kf.state_transition * kf.state.cov * kf.state_transition' + kf.process_cov
end
```

As can be seen, this step does not require any outside input, the filter encodes all of the information necessary to predict the state of the system after a single timestep given the existing state. 

Also, I am making my code and variable names verbose so as to clearly show what is going on, as the equations involved in the Kalman filter are quite long.

Next let's implement the update step:

```julia:filter-update
function kalman_update!(kf::KalmanFilter, measurement::Vector)
    y = measurement - kf.measurement_function*kf.state.mean

    kalman_gain = kf.state.cov*kf.measurement_function' * 
        inv(
            kf.measurement_function*kf.state.cov*kf.measurement_function' + 
            kf.measurement_noise_cov
        )

    kf.state.mean += kalman_gain*y

    I_mat = I(size(kalman_gain, 1))

    kf.state.cov = (I_mat - kalman_gain*kf.measurement_function) * kf.state.cov *
        (I_mat - kalman_gain*kf.measurement_function)' + 
        kalman_gain*kf.measurement_noise_cov*kalman_gain'
end
```

This function takes in a vector of measurements, and using this measurements to refine the prediction of the filter.

Finally I'll define a thin wrapper to run both steps given a measurement and update the state mean and covariance:

```julia:filter-wrapper
function kalman_step!(kf::KalmanFilter, measurement::AbstractVector)
    kalman_predict!(kf)
    kalman_update!(kf, measurement)
end
```

# Running a Simple Tracking Simulation

To test our code, let's do a simple example involving the tracking of an object moving at a constant speed. In the one-dimensional case, our equations of motion for our object are:

$$
\begin{aligned} x_{k+1} &= x_k + \dot x_k \Delta t \\ \dot x_{k+1} &= \dot x_k \end{aligned}
$$

From these equations, the state transition matrix can easily be defined:

$$ \mathbf F = \begin{bmatrix} 1 & \Delta t \\ 0 & 1 \end{bmatrix} $$

First let's define some helper functions to generate some data, and to run the filter for the entire simulation timespan:

```julia:sim-functions
function compute_test_data(z_var, process_var; count=1, dt=1.0)
    x, vel = 0.0, 1.0
    
    z_noise = Normal(0.0, sqrt(z_var))
    p_noise = Normal(0.0, sqrt(process_var))
    
    xs, zs = Float64[], Float64[]
        
    for _ in 1:count
        v = vel + rand(p_noise)
        x += v * dt
        
        push!(xs, x)
        push!(zs, x + rand(z_noise))
    end
    
    return xs, zs
end

function run_filter(count, filter::KalmanFilter; z_var=10.0, process_var=0.01)
    track, zs = compute_test_data(z_var, process_var, count=count, dt=dt)
    
    xs, cov = [], []
    
    for z in zs
        kalman_step!(filter, [z])
        
        push!(xs, filter.state.mean)
        push!(cov, filter.state.cov)
    end
    
    return xs, cov, zs, track
end
```

Let's define the parameters for our filter and run the simulation:

```julia:sim
x = [0.0, 0.0]

P = [
    500.0 0.0
    0.0 49.0
]

dt = 1.0

F = [
    1 dt
    0 1
]

Q = I(2).*0.01

H = [1 0]

R = [10.0]

test_filter = KalmanFilter(State(x, P), F, Q, H, R)

xs, cov, zs, track = run_filter(50, test_filter)
```

Let's see how well our filter performed:

```julia:sim-result
fig1 = Figure()
ax1 = Axis(fig1[1,1]; ylabel="Position (m)")

# plotting true position
times = LinRange(0, 50, 50)
lines!(
    ax1, times, track; 
    label="Track", linestyle=:dash, color="#002c40"
)

# plotting filter results and position variance
position = [x[1] for x in xs]
position_cov = [sqrt(c[1,1]) for c in cov]

lines!(ax1, times, position; label="Filter", color="#ffa600")	
band!(
    ax1, times, 
    position .+ position_cov, position .- position_cov; 
    color=("#ffa600", 0.25)
)

# plotting measurements
scatter!(
    ax1, times, zs; 
    label="Measurements", marker=:utriangle, color="#007f52"
)

axislegend(ax1; position=:rb)

ax12 = Axis(fig1[2,1]; xlabel="Time (s)", ylabel="Variance", yscale=log10)

lines!(ax12, times, position_cov, label="Position")
lines!(ax12, times, [sqrt(c[2,2]) for c in cov], label="Velocity")

axislegend(ax12)

fig1
save("assets/posts/kalman-filter-julia/code/fig1.svg", fig1) #hide
```

@@im-100
\fig{fig1}
@@

Obviously this filter can be adjusted and tuned for better performance, but we can clearly see that the filter estimates appear closer to the actual track than if we were to take the measurements as the "true" value of the system. Using Gaussian distributions to model our state also provides the benefit of giving a measure of the uncertainty of our state.

We can also see the position and velocity variances lowering then plateauing over time. A filter should settle over time, but due to the inherent noise present in the system, it will never reach zero variance.

<!-- 
```julia:sim2
num_sims = 50
position_results = []

for _ in 1:num_sims
    sim_filter = KalmanFilter(State(x, P), F, Q, H, R)
    
    sim_xs, sim_cov, sim_zs, sim_track = run_filter(50, sim_filter; process_var=0.0)

    push!(position_results, [x[1] for x in sim_xs])
end

fig2 = Figure()
ax2 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Position (m)")

lines!(ax2, times, times, label="Track", linestyle=:dash, color="#002c40")

for (i, pos) in enumerate(position_results)
    if i == 1
        lines!(ax2, times, pos, label="Filter", color=("#007f52", 0.25))
    else
        lines!(ax2, times, pos, color=("#007f52", 0.25))
    end
end

axislegend(ax2, position=:rb)

fig2
save("assets/posts/kalman-filter-julia/code/fig2.svg", fig2) #hide
```

@@im-100
\fig{fig2}
@@ -->

# Conclusion

This was a very brief and minimal implementation of a linear Kalman filter in Julia. There is much more theory and further work that goes into state estimation, so if you're intersted in learning more, please see the excellent reference below. Regardless, I hope this post was helpful in some way.

I am trying to update this blog on a regular basis again, however (fortunately for me) I have found a fulltime job and will have much less time to write regularly from here on out. I really enjoy writing these posts and learning interesting things, so I will try my best to keep putting stuff out, potentially mixing more casual posts in the style of [my previous one](https://michaszj.github.io/starcoffee/posts/on-dws-in-tft/). 

Until next time.

# References

- [Kalman and Bayesian Filters in Python](https://github.com/rlabbe/Kalman-and-Bayesian-Filters-in-Python)