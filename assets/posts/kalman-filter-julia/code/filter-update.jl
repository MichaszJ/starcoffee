# This file was generated, do not modify it. # hide
function kalman_update!(kf::KalmanFilter, measurement::Vector)
    y = measurement - kf.measurement_function*kf.state.mean

    kalman_gain = kf.state.cov*kf.measurement_function' * 
        inv(
            kf.measurement_function*kf.state.cov*kf.measurement_function' + 
            kf.measurement_noise_cov
        )

    kf.state.mean += kalman_gain*y

    I_mat = I(size(kalman_gain, 1))

    kf.state.cov = (I_mat - kalman_gain*kf.measurement_function) * kf.state.cov *
        (I_mat - kalman_gain*kf.measurement_function)' + 
        kalman_gain*kf.measurement_noise_cov*kalman_gain'
end