# This file was generated, do not modify it. # hide
times = 0:1:5*60
ϕ_vec = simple_sol(times)[spacecraft.Ix.phi]

function handle_angle(angle)
    if abs(angle) > pi
        a = angle
        while a > pi
            a -= 2*pi
        end
        return a
    else
        return angle
    end
end

fig2 = Figure()
ax2 = Axis(fig2[1,1], xlabel="Time (s)", ylabel="Angle (°)")

lines!(ax2, times, rad2deg.(handle_angle.(ϕ_vec)))

fig2
save("assets/posts/acausal-sadc-modelling/code/simple-vis.svg", fig2) #hide