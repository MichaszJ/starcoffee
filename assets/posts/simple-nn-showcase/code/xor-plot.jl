# This file was generated, do not modify it. # hide
plot(
    xor_losses,
    xlabel="Epoch", ylabel="Cross-Entropy Loss", label="",
    size=(800,500), dpi=300
)
savefig(joinpath(@OUTPUT, "xor-plot.svg")) # hide