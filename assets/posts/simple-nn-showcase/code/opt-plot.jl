# This file was generated, do not modify it. # hide
loss_gd = [loss[1] for loss in opt_losses]
loss_mgd = [loss[2] for loss in opt_losses]
loss_rms = [loss[3] for loss in opt_losses]
loss_adam = [loss[4] for loss in opt_losses]

plot(loss_gd, xlabel="Epoch", ylabel="Cross-Entropy Loss", label="Gradient Descent", size=(800,500), dpi=300)
plot!(loss_mgd, label="Momentum")
plot!(loss_rms, label="RMSprop")
plot!(loss_adam, label="ADAM")
savefig(joinpath(@OUTPUT, "opt-plot.svg")) # hide