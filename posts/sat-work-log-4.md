@def title = "SAT Work Log 4"
@def published = "April 13th, 2023"
@def tags = ["Julia", "Programming", "Aerospace", "Blogging", "Satellite Analysis Toolkit", "Work Log"]

# SAT Work Log 4

_By Michal Jagodzinski - Work Log - April 13th, 2023_

<!-- @def reeval = true -->

\tableofcontents

@@im-100
![](https://source.unsplash.com/9G8K_nycv7s)
@@

@@img-caption
Photo by [Zetong Li](https://unsplash.com/photos/9G8K_nycv7s)
@@

Hello and welcome back to Star Coffee. I've been pretty busy with life stuff this past week, so this will be a shorter post. But I still got some new cool stuff to showcase in the Satellite Analysis Toolkit.

## Plotting Multiple Satellites in GroundTracker

To plot multiple satellites, I first wrote a `GroundTrackerSatellite` struct to contain all the required information for plotting:

```julia
mutable struct GroundTrackerSatellite
    name::String
    elements::Observable{Vector{Float64}}
    ground_track_coords::Union{Observable{Matrix{Float64}}, Nothing}
    pos_coords::Union{Observable{Matrix{Float64}}, Nothing}

    function GroundTrackerSatellite(
        name::String,
        elements::Observable{Vector{Float64}}
    )

        return new(name, elements, nothing, nothing)
    end
end
```

I defined the `ground_track_coords` and `pos_coords` fields as type unions as those values are undefined at first and later calculated, as they are dependent on the orbital elements of the satellite. The fields are also defined as `Observable` values to allow for interactive plotting.

Now, a `Dict` of `GroundTrackerSatellite` structs can be used to plot multiple satellites in GroundTracker. This dictionary is initialized using the individual satellite elements, e.g.,

```julia
sats = Dict(
    "Sat 1" => GroundTrackerSatellite(
        "Sat 1",
        Observable([
            10000,
            0.19760,
            deg2rad(60),
            deg2rad(270),
            deg2rad(45),
            deg2rad(230)
        ])
    ),
    "Sat 2" => GroundTrackerSatellite(
        "Sat 2",
        Observable([
            8350,
            0.05,
            deg2rad(60),
            deg2rad(270),
            deg2rad(45),
            deg2rad(50)
        ])
    ),
)
```

I'm planning to eventually write a constructor for this struct that implements `Unitful.jl` units and validation of the orbital element values.

Next I rewrote the GroundTracker plotting and interactivity functions to loop through the `GroundTrackerSatellite` dictionary to update the orbit and ground track plots of each satellite. Based on the defined `Dict`, GroundTracker properly displays multiple satellites:

@@im-100
\fig{multi-sat-plot.png}
@@

I've also tried getting the `SliderGrid` to change its values when changing between satellites, but it doesn't work. The slider values don't visually update when changing between satellites, even though their internal values do. I'll keep working at it to try and get this functionality to work, but I may resort to using a dedicated GUI library to implement this. Plus text input in `Makie.jl` is also bugged, so using a GUI library would allow for that as well.

## Ground Station Visibility Analysis

An important consideration when deploying satellites is ground station visibility. The satellite must be in view of a ground station in order to send signals to it. For a satellite to be in view of a ground station with a minimum elevation angle $\varepsilon_\text{min}$, the following condition must be true:

$$
\frac{\pi}{2} - \cos^{-1} \left(\frac{\hat{n} \cdot \vec{s}}{||s||}\right) \geq \varepsilon_\text{min}
$$

Where

$$
\vec{s} = \vec{r}_{\text{sat}} - \vec{r}_{\text{gs}} \quad \quad \hat{n} = \frac{\vec{r}_{\text{gs}}}{||\vec{r}_{\text{gs}}||}
$$

For implementation in GroundTracker, the user just needs to specify the location and minimum elevation of a ground station, and then the condition needs to be calculated using the satellite's position in the ECI frame. Like each individual satellite, the ground stations can be stored as a `Dict` of `GroundStation` structs, defined as:

```julia
struct GroundStation
    name::String
    position::Vector{Float64}
    min_elevation::Float64
end

ground_stations = Dict(
    "GS 1" => GroundStation(
        "GS 1",
        [2761.8, 4783.5, 3189.0],
        deg2rad(5.0)
    )
)
```

Next the function to check the visibility condition can be simply written as:

```julia
	function check_gs_visibility(
        station::GroundStation,
        sat_position::Vector{Float64}
    )

    slant = sat_position - station.position
    slant_range = norm(slant)
    local_vert = station.position ./ norm(station.position)
    elevation = π/2 - acos(dot(local_vert, slant) / slant_range)

    return elevation >= station.min_elevation
end
```

To check if a satellite is in view of a ground station, the colour of marker or orbit line of the satellite can be set according to the visibility condition:

@@im-100
\fig{visibility-plot.png}
@@

I still need to work on improving the implementation of this system, but the basic building blocks are there. As can be seen in the image above, it's currently impossible to differentiate the satellites apart, so I would need to implement unique pairs of colour for each individual satellite to use. I would also need to implement a way for visibility analysis to work with multiple ground stations. I could potentially create a dropdown menu to select a specific ground station to use for visibility analysis, as well as a toggle to turn visibility analysis on and off.

## Conclusion

I am planning to keep adding more features to GroundTracker over time. One big feature I'd like to implement is thermal analysis, though this may become its own separate interactive tool instead. A satellite's thermal properties is another important consideration in satellite design, as some components require certain ranges of temperatures to function.

Thanks for reading! I will probably switch gears for the next post and start working on an interactive tool for plotting the results of simulations using the orbit propagators I defined in the previous posts. Until next time.
