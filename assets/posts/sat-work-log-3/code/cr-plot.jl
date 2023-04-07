# This file was generated, do not modify it. # hide
function circle(x, y, r)
    θ = LinRange(0, 2*π, 500)
    x .+ r*sin.(θ), y .+ r*cos.(θ)
end

cr3bp_interp = cr_three_body_sol(0.0 : 50 : 3.4 * 24 * 60 * 60)

plot(
    cr3bp_interp[x] ./ 1e3, cr3bp_interp[y] ./ 1e3,
    xlabel="x (km)", ylabel="y (km)",
    size=(800,500),
    aspect_ratio=:equal,
    label=""
)

plot!(
    circle(-4671, 0, 6378),
    seriestype = [:shape,],
    lw=0.5, c = :lightblue, fillalpha=0.5,
    label=""
)

plot!(
    circle(-4671 + 384400, 0, 1737.4),
    seriestype = [:shape,],
    lw=0.5, c = :gray, fillalpha=0.5,
    label=""
)
savefig(joinpath(@OUTPUT, "cr-plot.svg")) # hide