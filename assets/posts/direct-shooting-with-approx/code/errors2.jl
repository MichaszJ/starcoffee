# This file was generated, do not modify it. # hide
fig6=Figure()

ax6=Axis(
    fig6[1,1],
    xlabel="Iteration", ylabel="Error",
    yscale=log10, yminorticksvisible = true,
    yminorgridvisible = true, yminorticks = IntervalsBetween(9),
    xticks=1:2:n_iters+2
)

lines!(ax6, errors2)

fig6
save("assets/posts/direct-shooting-with-approx/code/errors2.svg", fig6) #hide