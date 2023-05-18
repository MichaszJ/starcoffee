# This file was generated, do not modify it. # hide
fig3 = Figure(resolution=(800,400))
ax31 = plot_opt_variable(fig3[1,1], C_L, L"C_L")

fig3
save("assets/posts/optimal-control-jump/code/glider-control.svg", fig3) #hide