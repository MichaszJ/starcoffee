# This file was generated, do not modify it. # hide
test_predictions = argmax.([
    Forward(mnist_network, convert(Vector{Float32}, flatten(test_x[1:end, 1:end, i]))) for i in 1:size(test_x, 3)
]) .- 1

test_correct = test_predictions .== test_y

println("Accuracy: $(round(100 * sum(test_correct) / length(test_correct), digits=2))%")