# This file was generated, do not modify it. # hide
fig1 = Figure(resolution=(900,350))

ax11 = Axis(
    fig1[1,1], aspect = DataAspect(),
    xlabel="x (m)", ylabel="y (m)"
)

lines!(ax11, value.(x_proj)[:], value.(y_proj)[:])
scatter!(ax11, [xt], [yt])

fig1
save("assets/posts/optimal-control-jump/code/target-optim.svg", fig1) #hide