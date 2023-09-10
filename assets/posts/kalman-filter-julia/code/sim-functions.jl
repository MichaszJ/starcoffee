# This file was generated, do not modify it. # hide
function compute_test_data(z_var, process_var; count=1, dt=1.0)
    x, vel = 0.0, 1.0
    
    z_noise = Normal(0.0, sqrt(z_var))
    p_noise = Normal(0.0, sqrt(process_var))
    
    xs, zs = Float64[], Float64[]
        
    for _ in 1:count
        v = vel + rand(p_noise)
        x += v * dt
        
        push!(xs, x)
        push!(zs, x + rand(z_noise))
    end
    
    return xs, zs
end

function run_filter(count, filter::KalmanFilter; z_var=10.0, process_var=0.01)
    track, zs = compute_test_data(z_var, process_var, count=count, dt=dt)
    
    xs, cov = [], []
    
    for z in zs
        kalman_step!(filter, [z])
        
        push!(xs, filter.state.mean)
        push!(cov, filter.state.cov)
    end
    
    return xs, cov, zs, track
end