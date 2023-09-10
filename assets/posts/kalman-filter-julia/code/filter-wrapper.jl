# This file was generated, do not modify it. # hide
function kalman_step!(kf::KalmanFilter, measurement::AbstractVector)
    kalman_predict!(kf)
    kalman_update!(kf, measurement)
end