# This file was generated, do not modify it. # hide
function plot_opt_variable(fig_ax, y, ylabel)
    ax = Axis(fig_ax, xlabel="Time (s)", ylabel=ylabel)
    lines!(ax, (1:n_glider) * value.(Δt), value.(y)[:])
    return ax
end

fig2 = Figure(resolution=(1000,500))

ax21 = plot_opt_variable(fig2[1,1], x, "Horizontal Distance (m)")
ax22 = plot_opt_variable(fig2[1,2], y, "Altitude (m)")
ax23 = plot_opt_variable(fig2[2,1], vx, "Horizontal Velocity (m/s)")
ax24 = plot_opt_variable(fig2[2,2], vy, "Vertical Velocity (m/s)")

fig2
save("assets/posts/optimal-control-jump/code/glider-optim.svg", fig2) #hide