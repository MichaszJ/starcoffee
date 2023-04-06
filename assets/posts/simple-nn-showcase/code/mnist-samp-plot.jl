# This file was generated, do not modify it. # hide
samps = rand(1:size(test_x, 3), 4)

test_preds = [
    Forward(mnist_network, convert(Vector{Float32}, flatten(test_x[1:end, 1:end, samp]))) for samp in samps
]

preds = [findmax(pred)[2] - 1 for pred in test_preds]

plots = []
for (i, pred) in enumerate(preds)
    temp = heatmap(
        test_x[1:end, 1:end, samps[i]]',
        yflip=true,
        title="Target = $(test_y[samps[i]]) | Prediction = $pred",
    )

    push!(plots, temp)
end

plot(plots..., layout=(2,2), size=(700,600), dpi=300)
savefig(joinpath(@OUTPUT, "mnist-samp-plot.svg")) # hide