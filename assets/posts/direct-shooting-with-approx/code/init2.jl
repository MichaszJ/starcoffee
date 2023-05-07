# This file was generated, do not modify it. # hide
F12 = [sol12[x, end], sol12[y, end]] .- target2
F22 = [sol22[x, end], sol22[y, end]] .- target2

dF2 = [
    (F22[1] - F12[1])/(ẋ2 - ẋ1) (F22[1] - F12[1])/(ẏ2 - ẏ1)
    (F22[2] - F12[2])/(ẋ2 - ẋ1) (F22[2] - F12[2])/(ẏ2 - ẏ1)
]

ẋ3_sim2, ẏ3_sim2 = [ẋ2, ẏ2] .- pinv(dF2)*F22