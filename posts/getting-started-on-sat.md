@def title = "Getting Started on SAT"
@def published = "April 2nd, 2023"
@def tags = ["Julia", "Programming", "Blogging", "Satellite Analysis Toolkit", "Work Log"]

# Getting Started on SAT

_By Michal Jagodzinski - Work Log - April 2nd, 2023_

The [Satellite Analysis Toolkit](https://github.com/MichaszJ/satellite-analysis-toolkit) (SAT) is my latest project I've been working on for the past couple days as of writing. It's based on an older project of mine called [Orbit Tool](https://github.com/MichaszJ/orbit-tool). Orbit Tool is a pretty simple [Streamlit](https://streamlit.io/) app that simulates orbits and plots ground tracks of satellites around Earth. I've been wanting to expand on Orbit Tool but found Streamlit a bit limiting for my needs. I attempted to rewrite the project [using Julia and Genie.jl](https://github.com/MichaszJ/orbit-tool-v2), but I found using Genie a little convoluted and did not make too much progress.

To scratch my itch of making software to analyze the functioning and behaviour of satellites, I started work on SAT. This time, I am focusing mostly on the analysis code itself, not web development. I still wanted some level of functionality, so I decided to use the plotting library [Makie.jl](https://docs.makie.org/), which provides interactive functionality. I will also eventually be creating some simple [Pluto.jl](https://plutojl.org/) notebooks with interactivity.

The majority of the code, at least in the short-term, will be mainly based off of my [scripts repository](https://github.com/MichaszJ/scripts), where I compiled a bunch of useful code from my undergrad and other projects. The scope of this project is for personal use and education, so I am not planning on actually developing it into a professional product or anything.

## The Progress So Far

So far I have built an interactive `Makie.jl` visualization called [OrbitTool.jl](https://github.com/MichaszJ/satellite-analysis-toolkit/blob/main/src/GroundTracker.jl) for visualizing a satellite's orbit around the Earth and its ground tracks. The orbit is plotted in an [ECI reference frame](https://en.wikipedia.org/wiki/Earth-centered_inertial), and the ground track plot has a setting to change the projection being used.

\fig{orbit-plot.png}

The algorithm that calculates the ground track points comes from _Orbital Mechanics for Engineering Students_ by Howard Curtis. If you are interested in learning orbital mechanics I recommend this textbook. I used this textbook during my orbital dynamics course and found it very approachable. It includes a lot of algorithms that you can easily implement in your programming language of choice, as I did in this project using Julia.

@@im-100
\fig{ground-track-plot.png}
@@

I've also implemented sliders to adjust the orbital elements of the plotted satellite, it's honestly really fun just playing around with the sliders and seeing how the orbit of the satellite changes. [Check out my tweet to see this in action.](https://twitter.com/astra_kawa/status/1642068166757982209)

The code is still pretty messy, especially when dealing with Observables and interactivity. I'm not sure why, but working with them is just a hassle sometimes. But it works, now I just need to do some cleaning up and optimization.

## What's Next?

In the next short while I will be focusing on polishing up the `OrbitTool.jl` component, I am not fully satisfied with the layout of the interactive components and will be wrestling with Makie to get it looking decent. I am also planning on adding some additional features:

- Add orthographic projection mode with adjustable longitude and latitude limits (see [MakieOrg/GeoMakie.jl](https://github.com/MakieOrg/GeoMakie.jl))
- Add functionality for plotting multiple satellites
- Add functionality for adding ground stations and visibility analysis

My next big interactive script I am planning to do is a simulator for various orbit types, such as two-body, three-body, restricted three-body, etc. This component will pretty much be the actual recreation of the old Orbit Tool.

I am still trying to think of other big components to add, I want to try and implement stuff that could _actually_ be useful for potential engineering work, but the scope of SAT still remains as a personal project for self-use and education.

I am excited to keep working on SAT and seeing how this toolkit evolves. I am really enjoying using Julia and Makie so far making the `OrbitTool.jl` component. Feel free to reach out on [Twitter](https://twitter.com/astra_kawa) if you have any interesting ideas you want me to take on and implement.

Thanks for reading! I hope to have more written on here soon. I have a lot of half-baked experiments that I want to write about but feel that they are not complete enough for a post on my Substack, so expect to see a lot of updates here and there. I also hope to have more posts focusing on code and math moreso than explaining my past work, so expect to see that soon too hopefully. Until next time!
