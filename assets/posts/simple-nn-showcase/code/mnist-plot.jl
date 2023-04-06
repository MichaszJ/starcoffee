# This file was generated, do not modify it. # hide
p1 = plot(batch_losses, yaxis=:log, label="Batch Loss")
p2 = plot(validation_accuracies, label="Validation Accuracy")

plot(p1, p2, layout=(1,2), size=(800,400), dpi=300)
savefig(joinpath(@OUTPUT, "mnist-plot.svg")) # hide