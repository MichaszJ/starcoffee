# This file was generated, do not modify it. # hide
fig2 = Figure()
ax21 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Controller Output")

lines!(ax21, 120:0.1:180, bb_sol(120:0.1:180)[bangbang_controller.ctrl_output.u])

fig2
save("assets/posts/sac-thrusters/code/bb-ss.svg", fig2) #hide