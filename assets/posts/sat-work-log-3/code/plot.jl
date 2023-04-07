# This file was generated, do not modify it. # hide
interp = three_body_sol(0.0:0.001:10.0)

plot(interp[x₁], interp[y₁], interp[z₁], size=(600,500), dpi=300)
plot!(interp[x₂], interp[y₂], interp[z₂])
plot!(interp[x₃], interp[y₃], interp[z₃])
savefig(joinpath(@OUTPUT, "3b-plot.svg")) # hide