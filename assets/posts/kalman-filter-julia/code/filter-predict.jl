# This file was generated, do not modify it. # hide
function kalman_predict!(kf::KalmanFilter)
    kf.state.mean = kf.state_transition * kf.state.mean
    kf.state.cov = kf.state_transition * kf.state.cov * kf.state_transition' + kf.process_cov
end