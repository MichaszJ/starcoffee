@def title = "Modelling Spacecraft Orbits with J2 Perturbation"
@def subtitle = "Simulating more realistic orbits and improving the GroundTracker backend"
@def published = "June 19th, 2023"
@def author = "Michal Jagodzinski"
@def tags = ["Julia", "Programming", "Aerospace", "Blogging", "Satellite Analysis Toolkit", "Orbital Dynamics"]

@def mintoclevel=1

<!-- @def reeval = true -->

{{ generate_title "modelling-J2-perturbation.md" }}

@@im-100
![](https://source.unsplash.com/fGyFiV_Yobw)
@@

@@img-caption
Photo by [Yevhenii Dubrovskyi](https://unsplash.com/photos/fGyFiV_Yobw)
@@

Hello and welcome back to Star Coffee. I'm back with some more orbital dynamics as well as improvements to GroundTracker, hopefully increasing performance and achieving greater simulation accuracy. Let's get into it.

\tableofcontents

# Motivation

The algorithm that I have been using in GroundTracker thus far works, but I haven't been too happy with its performance. Additionally, I have been wanting to include gravitational perturbation effects to make the simulated orbits more accurate. Finally, I have also been wanting to use `ModelingToolkit.jl` to run the simulations for me. So I figured it's finally time that I rewrite the code that calculates the orbits and ground tracks for satellites in `GroundTracker`.

# Implementing the J2 Perturbation Model

First, let's implement the $J_2$ perturbation model. In my previous posts regarding orbital dynamics, we have been assuming that the bodies being considered are point masses. For a point mass $m_s$ orbiting another point mass $m_p$ where $m_p \gg m_s$, the motion of $m_s$ with respect to $m_p$ is given by:

$$
\ddot{\mathbf r} = - \frac{\mu}{r^3} \mathbf{r}
$$

Where $\mu = G m_p$. Of course in real-life, point-masses do not exist, and if we want to more accurately simulate the motion of a satellite in orbit around Earth, we need to take into account the actual shape of the Earth[^1]. More specifically, we need to take into account that the Earth is an oblate spheroid, not a perfect sphere, and the force of gravity a satellite experiences varies at constant distances from the Earth.

We can model the influence of the non-sphericity of the Earth as a perturbative force $\mathbf f_p$ (or any other perturbative forces), and include this term in the above equation to get a better model for the motion of a satellite:

$$
\ddot{\mathbf r} = - \frac{\mu}{r^3} \mathbf{r} + \mathbf f_p
$$

For the Earth, a simple model we can implement is the $J_2$ model, which assumes that the Earth is a rotationally symmetric body about its axis of rotation. The $J_2$ (second zonal harmonic) term is the dominant perturbing force, which is why we are considering it. I am not going to derive how the term is calculated, it requires a long proof involving gravitational potentials. See the reference at the bottom of the post if you're interested. For the Earth, the $J_2$ constant has the following numerical value:

$$ J_2 = 1.083 \times 10^{-3} $$

The perturbing force as a result of the $J_2$ term is defined as[^2] :

$$
\mathbf f_p = \frac{3 \mu J_{2} R_{e}^2}{2r^5} \left[ \left( 5 \frac{\left( \mathbf{r}^\intercal \mathbf{z}_{G} \right)^2}{r^2} - 1 \right) \mathbf{r} - 2\left( \mathbf{r}^\intercal \mathbf{z}_{G} \right) \mathbf{z}_{G} \right]
$$

@@im-100
\fig{perturbative-comp.svg}
@@

@@img-caption
Components of $J_2$ perturbation on satellite in 300 km circular orbit with $i = 30^\circ$ along one orbit
@@

We can now include this perturbing force in the satellite's equations of motion:

$$
\ddot{\mathbf{r}} = -\frac{\mu}{r^3} \mathbf{r} + \frac{3 \mu J_{2} R_{e}^2}{2r^5} \left[ \left( 5 \frac{\left( \mathbf{r}^\intercal \mathbf{z}_{G} \right)^2}{r^2} - 1 \right) \mathbf{r} - 2\left( \mathbf{r}^\intercal \mathbf{z}_{G} \right) \mathbf{z}_{G} \right]
$$

After expanding the three components of $\ddot{\mathbf{r}}$ and simplifying with the help of [Wolfram Language](https://www.wolfram.com/language/), we now have the following equations of motion for a satellite with $J_2$ perturbation:

$$
\begin{align*}
\ddot{x} &= - \frac{\mu}{r^3} x - \frac{3 \mu J_2 R_e^2 x (r^2 - 5z^2)}{2r^7} \\
\ddot{y} &= - \frac{\mu}{r^3} y - \frac{3 \mu J_2 R_e^2 y (r^2 - 5z^2)}{2r^7} \\
\ddot{z} &= - \frac{\mu}{r^3} z + \frac{3 \mu J_2 R_e^2 z (5z^2 - 3r^2)}{2r^7}
\end{align*}
$$

Other orbital perturbations exist, such as atmospheric drag, solar radiation pressure, lunar and solar gravity, etc., however we will only be considering $J_2$ perturbation for now.

# Calculating ECEF Coordinates and Geodetic Coordinates

The equations we defined above give the coordinates of a spacecraft in the [Earth-centered inertial](https://en.wikipedia.org/wiki/Earth-centered_inertial) (ECI) reference frame. This reference frame is fixed relative to the stars, it does not rotate with the Earth. If we want to plot ground tracks, we first need to convert the coordinates of the satellite to the [Earth-centered Earth-fixed](https://en.wikipedia.org/wiki/Earth-centered,_Earth-fixed_coordinate_system) (ECEF) reference frame, which does rotate with the Earth.

@@im-100
\fig{ECI-ECEF-Coords.svg}
@@

@@img-caption
A comparison of ECI and ECEF coordinates for the same orbit.
@@

This can be done by applying a rotation to the ECI coordinates about the $z$ axis:

$$
\begin{bmatrix} E \\ F \\ G \end{bmatrix} = \mathbf{R} (\theta)_z \begin{bmatrix} x \\ y \\ z \end{bmatrix} = \begin{bmatrix} \cos \theta & - \sin \theta & 0 \\ \sin \theta & \cos \theta & 0 \\ 0 & 0 & 1 \end{bmatrix} \begin{bmatrix} x \\ y \\ z \end{bmatrix}
$$

Where $\theta$ is the angular rotation of the Earth that has occurred since Epoch, defined as:
$$ \theta = \omega_E t $$

Where $\omega_E$ is the angular velocity of the Earth, with a value of
$$ \omega_E = 0.2618 \; \text{rad/h} = 7.272 \times 10^{-5} \; \text{rad/s}$$

We can easily expand the equation above:

$$
\begin{align*}
E &= x \cos \theta - y \sin \theta \\
F &= x \sin \theta + y \cos \theta \\
G &= z
\end{align*}
$$

Now that we have the ECEF coordinates, we can calculate the geodetic coordinates, latitude $\phi$, longitude $\lambda$, and altitude $h$. The problem with this is that there is no simple method to do this. There exist several algorithms to calculate the geodetic coordinates, the algorithm I implemented is a relatively simple iterative method.

First we approximate the geodetic coordinates using the following equations[^3] :

$$
\begin{align*}
\phi &= \arctan \left( \frac{G}{\sqrt{E^2 + F^2}} \frac{1}{(1 - f)^2} \right) \\
\lambda &= \arctan \left( \frac{F}{E} \right) \\
h &= \sqrt{E^2 + F^2 + G^2} - a \sqrt{\dfrac{1 - e^2}{1 - e^2 \cos \left[ \arctan \left( \frac{G}{\sqrt{E^2 + F^2}} \right) \right]^2}}
\end{align*}
$$

Where $f$ is the flattening parameter, $a$ is the semi-major axis of the Earth, and $e$ is the eccentricity of the Earth.

Next, we can recalculate the ECEF coordinates from these approximate values. The conversion from geodetic coordinates to ECEF coordinates is exact:

$$
\begin{align*}
\bar E &= (N(\phi) + h) \cos(\lambda) \cos (\phi) \\
\bar F &= (N(\phi) + h) \sin(\lambda) \cos (\phi) \\
\bar G &= \left[ N(\phi) (1 - e^2) + h \right] \sin \phi
\end{align*}
$$

Where $N(\phi)$ is the normal distance, defined as:

$$ N(\phi) = \frac{a}{\sqrt{1 - (e \sin \phi)^2}} $$

The numerical values for the constants are:

$$
\begin{align*}
f &= 1/298.257223563 \\
a &= 6378.137 \\
e &= \sqrt{2f - f^2} = 0.08181919084262149
\end{align*}
$$

We can then calculate the error from the approximated ECEF coordinates $(\bar E, \bar F, \bar G)$ using the exact ECEF coordinates $(E, F, G)$, adjust the geodetic coordinates based on the error, and repeat until we achieve a desirable error. This algorithm can be implemented easily in Julia[^4] :

```julia
const f = 1/298.257223563
const a = 6378.137
const e = sqrt(2*f - f^2)

function LLA_from_EFG_approx(E, F, G)
    ϕ = atan(G, sqrt(E^2 + F^2)*(1 - f)^2)
    λ = atan(F, E)
    h = sqrt(E^2 + F^2 + G^2) - a*sqrt((1 - e^2)/(1 - e^2 * cos(atan(G, sqrt(E^2 + F^2)))^2))

    return [ϕ, λ, h]
end

function normal_distance(ϕ)
    a / sqrt(1 - (e * sin(ϕ))^2)
end

function EFG_from_LLA(ϕ, λ, h)
    E = (normal_distance(ϕ) + h) * cos(λ) * cos(ϕ)
    F = (normal_distance(ϕ) + h) * sin(λ) * cos(ϕ)
    G = (normal_distance(ϕ) * (1 - e^2) + h)*sin(ϕ)

    return [E, F, G]
end

function LLA_from_EFG(E, F, G; tol=0.01)
    pos = [E, F, G]
    fakePos = copy(pos)
    result = LLA_from_EFG_approx(fakePos...)
    error = EFG_from_LLA(result...) .- pos

    while norm(error) > tol
        fakePos .-= error
        result = LLA_from_EFG_approx(fakePos...)
        error = EFG_from_LLA(result...) .- pos
    end

    return result
end
```

# Implementing in GroundTracker

Now that we can simulate the $J_2$ orbital model, and calculate the ECEF and geodetic coordinates, we can implement the above defined equations in `GroundTracker`. First, we can simulate the $J_2$ perturbed orbit and directly calculate the ECEF coordinates using `ModelingToolkit.jl`:

```julia
const ωe = 0.261799387799149/(60*60)
const J2 = 1.083e-3
const Re = 6378.137
const μ = 398600
const f = 1/298.257223563

@variables t x(t) y(t) z(t) ẋ(t) ẏ(t) ż(t) r(t) E(t) F(t) G(t)
D = Differential(t)

eqs = [
    r ~ sqrt(x^2 + y^2 + z^2),

    D(x) ~ ẋ,
    D(y) ~ ẏ,
    D(z) ~ ż,

    D(ẋ) ~ -μ*x/r^3 - 3*μ*J2*Re^2*x*(r^2 - 5*z^2)/(2*r^7),
    D(ẏ) ~ -μ*y/r^3 - 3*μ*J2*Re^2*y*(r^2 - 5*z^2)/(2*r^7),
    D(ż) ~ -μ*z/r^3 + 3*μ*J2*Re^2*z*(5*z^2 - 3*r^2)/(2*r^7),

    E ~ x*cos(ωe*t) - y*sin(ωe*t),
    F ~ x*sin(ωe*t) + y*cos(ωe*t),
    G ~ z
]

J2_system = structural_simplify(ODESystem(
    eqs,
    t,
    name=:J2_system
))
```

Next we can simulate the orbit, calculate the geodetic coordinates using the code defined above, and transform the results for plotting in `GroundTracker`:

```julia
# modified to return only longitude and latitude
function LLA_from_EFG(E, F, G; tol=0.01)
    pos = [E, F, G]
    fakePos = copy(pos)
    result = LLA_from_EFG_approx(fakePos...)
    error = EFG_from_LLA(result...) .- pos

    while norm(error) > tol
        fakePos .-= error
        result = LLA_from_EFG_approx(fakePos...)
        error = EFG_from_LLA(result...) .- pos
    end

    return reverse(result[1:2])
end

function calculate_ground_tracks(elements, tspan, num_steps)
    states = elements_to_state(elements...)

    u0 = Dict(
        x => states[1][1],
        y => states[1][2],
        z => states[1][3],
        ẋ => states[2][1],
        ẏ => states[2][2],
        ż => states[2][3]
    )

    prob = ODEProblem(
        J2_system,
        u0,
        tspan,
        [],
        jac=true
    )

    sol = solve(prob)

    times = LinRange(0, tspan[end], num_steps)
    interp = sol(times)

    ground_track_coords = rad2deg.(reduce(
        hcat, LLA_from_EFG.(interp[E], interp[F], interp[G])
    ))
    orbit_coords = Matrix(hcat(interp[E], interp[F], interp[G])')

    return ground_track_coords, orbit_coords
end
```

The result is that everything seems to work as expected.

@@im-100
\fig{ground-tracker.png}
@@

I have not benchmarked the old or this new system, but I expect the new one to be somewhat faster. Most importantly, this system is a lot easier to build upon, and it should be a lot more accurate in both the orbital positions of the satellite and the geodetic coordinates. I am planning to add tools for more analysis, so it's important to implement a system that's accurate and easy to work with.

# Conclusion

Thanks for reading! I hope this post was insightful. I haven't posted anything in a while, but I am planning on trying to get back on a regular writing schedule again. Hopefully I'll be posting more soon. Until next time.

# References

[^1]: The point-mass approximation is still fairly accurate, but over long timespans the errors become more significant.
[^2]: A.H.J. de Ruiter, C.J. Damaren, J.R. Forbes, "Orbital Perturbations," in Spacecraft Dynamics and Control: An Introduction, 1st Edition. West Sussex, UK: John Wiley & Sons Ltd., 2013.
[^3]: The equations for $\lambda$ and $h$ are actually exact, whereas the one for $\phi$ is the actual approximation.
[^4]: J. Stryjewski, [Coordinate Transformations](https://x-lumin.com/wp-content/uploads/2020/09/Coordinate_Transforms.pdf). 2020.
