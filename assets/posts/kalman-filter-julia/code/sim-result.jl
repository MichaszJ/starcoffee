# This file was generated, do not modify it. # hide
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