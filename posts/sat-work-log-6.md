@def title = "SAT Work Log 6"
@def subtitle = "Updates to GroundTracker and some ModelingToolkit.jl work"
@def published = "May 24th, 2023"
@def author = "Michal Jagodzinski"
@def tags = ["Julia", "Programming", "Aerospace", "Blogging", "Satellite Analysis Toolkit", "Work Log"]

@def mintoclevel=1

@def reeval = true

{{ generate_title "sat-work-log-6.md" }}

@@im-100
![](https://source.unsplash.com/kJG4v63b43E)
@@

@@img-caption
Photo by [Hunter Reilly](https://unsplash.com/photos/kJG4v63b43E)
@@

Hello and welcome back to Star Coffee. I haven't made many updates on SAT for a while now. I've been focusing on some other stuff plus my (lack of) mental health really makes it hard to be motivated to work. But I got back into active development on SAT a bit ago so here are some updates.

# Improvements to GroundTracker

@@im-100
\fig{groundtracker}
@@

A recent version of `GLMakie` brought a fix to a bug that's been incredibly annoying for me. The bug causes the text of interactive textboxes to appear in the bottom left corner of the screen. This is no longer the case, and the textbox text appears where it should. I have now implemented textboxes to edit the orbital elements of the satellites, giving much more precise control over the previously used sliders. I intended to use textboxes from the start, however due to the mentioned bug, I had to resort to using sliders to actually achieve the interactivity I wanted.

I have also gotten the functionality to switch between satellites working properly as well. The user is now able to switch which satellite's orbital elements are displayed in the UI and edit them.

Next I implemented a better system for managing the colours of individual satellites' data. Previously, after I implemented ground station visibility analysis, every satellite had the default `viridis` colour palette applied to it. Now, using `ColorSchemes.jl`, custom color schemes can be assigned for each satellite. The colour schemes are defined using the following `Dict`:

```julia
colormaps = Dict(
    "Sat 1" => cgrad(ColorScheme([
        colorant"#7E1717", colorant"#068DA9", colorant"#E55807"
    ]), 3, categorical=true),

    "Sat 2" => cgrad(ColorScheme([
        colorant"#146C94", colorant"#AFD3E2", colorant"#19A7CE"
    ]), 3, categorical=true)
)
```

The first colour corresponds to the satellite out of view for visibility analysis, the second is the default colour used when visibility analysis is disabled, and the third colour is the colour when the satellite is in view. I've also added a nice section to the UI to show all the satellites and their individual colours.

Here are some of the next things I'll be working on with GroundTracker:

- Implementing `DataInspector`s for the orbit and ground track plots to provide useful information for users
- Improve the algorithms for generating the orbits and ground tracks
- Create more tools for visibility analysis, possibly a separate dashboard that generates plots/analyses related to visibility analysis
- Create tools related to thermal analysis, such as eclipse determination

I'm also planning to read up on satellite operations-related topics to see what other potential functionality I can add that may be useful.

# Implementing Attitude Dynamics ModelingToolkit.jl Components

If you've been keeping up with the blog, I've recently published two posts on using `ModelingToolkit.jl` for spacecraft attitude dynamics and control. The [first on the linearized form of Euler's equations](https://michaszj.github.io/starcoffee/posts/acausal-sadc-modelling/) and the [second on the nonlinear form](https://michaszj.github.io/starcoffee/posts/nonlinear-sadc-modelling/). I rewrote the linear attitude component, getting rid of the extra `Flange` and other unnecessary components for it to be equivalent to the nonlinear one.

```julia
@component function LinearSpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=40.0, u0=zeros(3), ω0=zeros(3), ω̇0=zeros(3)
)
    @named Mx = B.RealInput()
    @named My = B.RealInput()
    @named Mz = B.RealInput()

    @named phi_x = B.RealOutput()
    @named phi_y = B.RealOutput()
    @named phi_z = B.RealOutput()

    @variables ϕ(t)=u0[1] θ(t)=u0[2] ψ(t)=u0[3]
    @variables ωx(t)=ω0[1] ωy(t)=ω0[2] ωz(t)=ω0[3]
    @variables ω̇x(t)=ω̇0[1] ω̇y(t)=ω̇0[2] ω̇z(t)=ω̇0[3]

    sts=[ϕ, θ, ψ, ωx, ωy, ωz, ω̇x, ω̇y, ω̇z]

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

        Mx.u ~ Jx * ω̇x,
        My.u ~ Jy * ω̇y,
        Mz.u ~ Jz * ω̇z
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), Mx, My, Mz, phi_x, phi_y, phi_z
    )
end
```

```julia
@component function SpacecraftAttitude(
    ; name, Jx=100.0, Jy=100.0, Jz=40.0, u0=zeros(3), ω0=zeros(3), ω̇0=zeros(3)
)
    @named Mx = B.RealInput()
    @named My = B.RealInput()
    @named Mz = B.RealInput()

    @named phi_x = B.RealOutput()
    @named phi_y = B.RealOutput()
    @named phi_z = B.RealOutput()

    @variables ϕ(t)=u0[1] θ(t)=u0[2] ψ(t)=u0[3]
    @variables ωx(t)=ω0[1] ωy(t)=ω0[2] ωz(t)=ω0[3]
    @variables ω̇x(t)=ω̇0[1] ω̇y(t)=ω̇0[2] ω̇z(t)=ω̇0[3]

    sts=[ϕ, θ, ψ, ωx, ωy, ωz, ω̇x, ω̇y, ω̇z]

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

        Mx.u ~ Jx * ω̇x - (Jy - Jz)*ωy*ωz,
        My.u ~ Jy * ω̇y - (Jz - Jx)*ωz*ωx,
        Mz.u ~ Jz * ω̇z - (Jx - Jy)*ωx*ωy
    ]

    compose(
        ODESystem(eqs, t, sts, ps; name = name), Mx, My, Mz, phi_x, phi_y, phi_z
    )
end
```

I'm planning to formalize these components more by including proper metadata and possibly integrating `Unitful.jl` units, however I have been getting some annoying errors lately using units. In time, I also want to separate the attitude representation of the spacecraft from the dynamics, currently they are both integrated in the `SpacecraftAttitude` components. Instead, I'd like to have some sort of arbitrary attitude component that is able to interface with a general dynamics component, so different attitude representations can be replaced easily in simulations.

I'm planning on adding some spacecraft environment disturbance components as well, such as gravity-gradient, aerodynamic, magnetic, etc. This would allow for more realistic simulations, however these components would also depend on the orbital dynamics of the spacecraft, so I would need to create components to model that as well.

# Wrapping Up

Thanks for reading. This has been a short post as I am still focusing on other stuff like finding employment. I am planning to keep working on SAT as well as learning more GNC-related topics so expect more posts soon. Until next time.
