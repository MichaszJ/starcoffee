# This file was generated, do not modify it. # hide
F1 = [sol1[x, end], sol1[y, end]] .- target
F2 = [sol2[x, end], sol2[y, end]] .- target

dF = [
    (F2[1] - F1[1])/(ẋ2 - ẋ1) (F2[1] - F1[1])/(ẏ2 - ẏ1)
    0 0
]

ẋ3_sim, ẏ3_sim = [ẋ2, ẏ2] .- pinv(dF)*F2