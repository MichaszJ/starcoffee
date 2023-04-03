# This file was generated, do not modify it. # hide
scatter(
    errors,
    yaxis=:log, minorgrid=true,
    label="", xlabel="Iteration", ylabel="Error",
    marker=:xcross
)
savefig(joinpath(@OUTPUT, "errors.svg")) # hide