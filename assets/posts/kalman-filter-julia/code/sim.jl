# This file was generated, do not modify it. # hide
x = [0.0, 0.0]

P = [
    500.0 0.0
    0.0 49.0
]

dt = 1.0

F = [
    1 dt
    0 1
]

Q = I(2).*0.01

H = [1 0]

R = [10.0]

test_filter = KalmanFilter(State(x, P), F, Q, H, R)

xs, cov, zs, track = run_filter(50, test_filter)