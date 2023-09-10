# This file was generated, do not modify it. # hide
mutable struct State
    mean::AbstractVector
    cov::AbstractMatrix
end

mutable struct KalmanFilter
    state::State
    state_transition::AbstractMatrix
    process_cov::AbstractMatrix
    measurement_function::AbstractMatrix
    measurement_noise_cov::AbstractArray
end