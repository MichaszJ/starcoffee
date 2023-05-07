# This file was generated, do not modify it. # hide
fig3=Figure()

ax3=Axis(
    fig3[1,1],
    xlabel="Iteration", ylabel="Error",
    yscale=log10, yminorticksvisible = true,
    yminorgridvisible = true, yminorticks = IntervalsBetween(9),
    xticks=1:2:n_iters+2
)

lines!(ax3, errors)

fig3
save("assets/posts/direct-shooting-with-approx/code/errors.svg", fig3) #hide