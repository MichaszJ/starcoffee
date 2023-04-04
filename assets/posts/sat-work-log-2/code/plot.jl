# This file was generated, do not modify it. # hide
times = 0.0:0.01:480.0
interp = two_body_sol(times)

plot(interp[x₁], interp[y₁], interp[z₁], label="Mass 1", dpi=300)
plot!(interp[x₂], interp[y₂], interp[z₂], label="Mass 2")
savefig(joinpath(@OUTPUT, "orbit-plot.svg")) # hide