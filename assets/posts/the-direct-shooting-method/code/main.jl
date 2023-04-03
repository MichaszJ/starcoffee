# This file was generated, do not modify it. # hide
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