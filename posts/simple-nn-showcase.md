# Simple NN Showcase

_April 6th, 2023_

@def reeval = true

\tableofcontents

@@im-100
![](https://source.unsplash.com/tevq6l3Niv0)
@@

@@img-caption
Photo by [Yasintha Perera](https://unsplash.com/photos/tevq6l3Niv0)
@@

`simple_nn` is a simple neural network framework, not much more to it. The functionality of `simple_nn` was inspired by [PyTorch](https://pytorch.org/) and [tinygrad](https://github.com/geohot/tinygrad). I wanted the ability for low-level control of the training process, allowing users to specify exactly how their model is trained.

I did the majority of the work for this project a couple of months ago, but I did not feel that it was complete enough to showcase on my [Substack](https://michaszj.substack.com/). But I do want to showcase it on here, and similar to [SAT](https://michaszj.github.io/starcoffee/posts/satellite-analysis-toolkit/), document the further work I do on it.

```julia:simplenn
#hideall
struct DenseLayer
    size::Tuple{Int, Int}
    params::Dict
    operation::Function
    activation::Function

    function DenseLayer(size::Tuple{Int, Int}, activation::Function; params=Dict())
        return new(size, params, dense_layer, activation)
    end
end

struct ConvLayer
    size::Tuple{Int, Int, Int}  # in channels, out channels, kernel size
    params::Dict                # padding, stride
    operation::Function
    activation::Function

    function ConvLayer(size::Tuple{Int, Int, Int}, activation::Function; params=Dict("Stride" => 1, "Padding" => 1))
        return new(size, params, conv_2d_layer, activation)
    end
end

struct PoolLayer
    size::Tuple{Int, Int, Int}  # in channels, out channels, kernel size
    params::Dict                # padding, stride
    operation::Function
    pool_function::Function

    function PoolLayer(size::Tuple{Int, Int, Int}, pool_operation::Function; params=Dict("Stride" => 1, "Padding" => 1))
        return new(size, params, pool_2d_layer, pool_operation)
    end
end

mutable struct Network
    layers::Vector
    biases::Vector
    weights::Vector
    params::Dict
end

function CreateNetwork(setup; datatype=Float32, init_distribution=Normal())
    biases, weights = [], []
    for layer in setup
        if typeof(layer) == DenseLayer
            push!(biases, convert.(datatype, rand(init_distribution, layer.size[2])))
            push!(weights, convert.(datatype, rand(init_distribution, layer.size[2], layer.size[1])))

        elseif typeof(layer) == ConvLayer
            push!(biases, [
                convert.(datatype, rand(init_distribution)) for _ in 1:layer.size[2]
            ])

            push!(weights, convert.(datatype, rand(init_distribution, layer.size[3], layer.size[3], layer.size[1], layer.size[2])))
        end
    end

    return Network(setup, biases, weights, Dict(["datatype" => datatype]))
end

function Forward(net::Network, a)
    for layer in 1:length(net.weights)
        if typeof(net.layers[layer]) == DenseLayer
            a = net.layers[layer].activation(net.layers[layer].operation(net, layer, a))

        elseif typeof(net.layers[layer]) == ConvLayer
            a = [net.layers[layer].activation(mat) for mat in net.layers[layer].operation(net, layer, a)]

        elseif typeof(net.layers[layer]) == PoolLayer
            a = net.layers[layer].operation(net, layer, a)
        end
    end

    return a
end

function OptimizerSetup!(net::Network, optimizer; optimizer_params...)
    optimizer_params = get_optimizer_params(net, optimizer; optimizer_params...)
    net.params = optimizer_params
end

function Backward!(net::Network, loss_function, x, y)
    grad = gradient(Params([net.weights, net.biases])) do
        loss_function(x, y)
    end

    net.params["optimizer"](net, grad[net.weights], grad[net.biases])
end

# functions
# layer types
function dense_layer(net::Network, layer::Int, a)
    if ndims(a) > 1
        return vec(vcat(a...)' * net.weights[layer]') .+ net.biases[layer]
    else
        return vec(a' * net.weights[layer]') .+ net.biases[layer]
    end
end

feature_dim(image_dim, kernel_dim, padding, stride) = Int((image_dim - kernel_dim + 2*padding) / stride + 1)

function pad_matrix(mat, padding; pad_value=0.0)
    n = size(mat, 2)
    return Matrix(PaddedView(pad_value, mat, (n + 2*padding, n + 2*padding), (1 + padding, 1 + padding)))
end

function conv_2d_layer(net::Network, layer::Int, a)
    padding, stride = net.layers[layer].params["Padding"], net.layers[layer].params["Stride"]

    n_f = feature_dim(size(a, 1), size(net.weights[layer], 1), padding, stride)
    n_k = size(net.weights[layer], 1)

    output_volume = [
        dot(a[(m + (m-1)*(stride-1)):m + (m-1)*(stride-1)+(n_k-1), (n + (n-1)*(stride-1)):n + (n-1)*(stride-1)+(n_k-1), :], net.weights[layer][:, :, :, i]) .+ net.biases[layer][i] for m in 1:n_f, n in 1:n_f, i in 1:size(net.weights[layer], 4)
    ]

    return output_volume
end

function pool_2d_layer(net::Network, layer::Int, a)
    stride = net.layers[layer].params["Stride"]

    n_k = mnist_cnn_network.layers[2].size[3]
    n_f = Int((size(a, 1) - n_k)/stride + 1)

    output_volume = [
        net.layers[layer].pool_function(a[(m + (m-1)*(stride-1)):m + (m-1)*(stride-1)+(n_k-1), (n + (n-1)*(stride-1)):n + (n-1)*(stride-1)+(n_k-1), i]...) for m in 1:n_f, n in 1:n_f, i in 1:size(a, 3)
    ]

    return output_volume
end

# activation functions
function none_activation(z)
    return z
end

function sigmoid_activation(z)
    return 1 ./ (1 .+ exp.(-z))
end

function relu_activation(z)
    return max.(Float32(0.0), z)
end


# numerically stable softmax activation
function softmax_activation(z)
    z = z .- maximum(z)
    return exp.(z) ./ sum(exp.(z))
end

# optimizer stuff
function get_optimizer_params(net::Network, optimizer; optimizer_params...)
    if string(optimizer) == "GradientDescentOptimizer!"
        params = Dict([
            "optimizer" => optimizer,
            "optimizer_name" => "GradientDescentOptimizer!",
            "learning_rate" => 0.01
        ])
    elseif string(optimizer) == "MomentumOptimizer!"
        params = Dict([
            "optimizer" => optimizer,
            "optimizer_name" => "MomentumOptimizer!",
            "learning_rate" => 0.01,
            "gamma" => 0.9,
            "weights_momentum_vector" => [zeros(size(layer)) for layer in net.weights],
            "biases_momentum_vector" => [zeros(size(layer)) for layer in net.biases]
        ])
    elseif string(optimizer) == "RMSpropOptimizer!"
        params = Dict([
            "optimizer" => optimizer,
            "optimizer_name" => "RMSpropOptimizer!",
            "learning_rate" => 0.01,
            "moving_average" => 0.9,
            "epsilon" => 1.0e-8,
            "weights_grad_vec" => [zeros(size(layer)) for layer in net.weights],
            "biases_grad_vec" => [zeros(size(layer)) for layer in net.biases]
        ])
    elseif string(optimizer) == "AdamOptimizer!"
        params = Dict([
           "optimizer" => optimizer,
           "optimizer_name" => "AdamOptimizer!",
           "decay_1" => 0.9,
           "decay_2" => 0.999,
           "step_size" => 0.01,
           "epsilon" => 1.0e-8,
           "weights_m" => [zeros(size(layer)) for layer in net.weights],
           "weights_v" => [zeros(size(layer)) for layer in net.weights],
           "biases_m" => [zeros(size(layer)) for layer in net.biases],
           "biases_v" => [zeros(size(layer)) for layer in net.biases]
       ])
    end

    if length(optimizer_params) > 0
        for param in optimizer_params
            params[string(param[1])] = param[2]
        end
    end

    return params
end

function GradientDescentOptimizer!(net::Network, weight_grad, bias_grad)
    net.weights = net.weights .- net.params["learning_rate"] * weight_grad
    net.biases = net.biases .- net.params["learning_rate"] * bias_grad
end

function MomentumOptimizer!(net::Network, weight_grad, bias_grad)
    net.params["weights_momentum_vector"] = net.params["gamma"] * net.params["weights_momentum_vector"] + net.params["learning_rate"] * weight_grad
    net.weights = net.weights .- net.params["weights_momentum_vector"]

    net.params["biases_momentum_vector"] = net.params["gamma"] * net.params["biases_momentum_vector"] + net.params["learning_rate"] * bias_grad
    net.biases = net.biases .- net.params["biases_momentum_vector"]
end

function RMSpropOptimizer!(net::Network, weight_grad, bias_grad)
    for layer in 1:length(net.layers)
        net.params["weights_grad_vec"][layer] = net.params["moving_average"] .* net.params["weights_grad_vec"][layer] .+ (1 .- net.params["moving_average"]) .* weight_grad[layer].^2
        net.params["biases_grad_vec"][layer] = net.params["moving_average"] .* net.params["biases_grad_vec"][layer] .+ (1 .- net.params["moving_average"]) .* bias_grad[layer].^2

        net.weights[layer] = net.weights[layer] .- net.params["learning_rate"] ./ sqrt.(net.params["weights_grad_vec"][layer] .+ net.params["epsilon"]) .* weight_grad[layer]
        net.biases[layer] = net.biases[layer] .- net.params["learning_rate"] ./ sqrt.(net.params["biases_grad_vec"][layer] .+ net.params["epsilon"]) .* bias_grad[layer]
    end
end

function AdamOptimizer!(net::Network, weight_grad, bias_grad)
    for layer in 1:length(net.layers)
        net.params["weights_m"][layer] = net.params["decay_1"] .* net.params["weights_m"][layer] .+ (1 .- net.params["decay_1"]) .* weight_grad[layer]
        weights_m_hat = net.params["weights_m"][layer] ./ (1 .- net.params["decay_1"])

        net.params["weights_v"][layer] = net.params["decay_2"] .* net.params["weights_v"][layer] .+ (1 .- net.params["decay_2"]) .* weight_grad[layer].^2
        weights_v_hat = net.params["weights_v"][layer] ./ (1 .- net.params["decay_2"])

        net.params["biases_m"][layer] = net.params["decay_1"] .* net.params["biases_m"][layer] .+ (1 .- net.params["decay_1"]) .* bias_grad[layer]
        biases_m_hat = net.params["biases_m"][layer] ./ (1 .- net.params["decay_1"])

        net.params["biases_v"][layer] = net.params["decay_2"] .* net.params["biases_v"][layer] .+ (1 .- net.params["decay_2"]) .* bias_grad[layer].^2
        biases_v_hat = net.params["biases_v"][layer] ./ (1 .- net.params["decay_2"])

        net.weights[layer] = net.weights[layer] .- weights_m_hat .* (net.params["step_size"] ./ (sqrt.(weights_v_hat) .+ net.params["epsilon"]))
        net.biases[layer] = net.biases[layer] .- biases_m_hat .* (net.params["step_size"] ./ (sqrt.(biases_v_hat) .+ net.params["epsilon"]))
    end
end
```

## Simple Example: The XOR Problem

```julia:imports
using LinearAlgebra, Distributions, Plots, Random, Zygote, MLDatasets
Random.seed!(69420)
```

Defining data:

```julia:xor-data
data = [
    [0.0, 0.0],
    [0.0, 1.0],
    [1.0, 0.0],
    [1.0, 1.0]
]

targets = [
    [0.0, 1.0],
    [1.0, 0.0],
    [1.0, 0.0],
    [0.0, 1.0]
]
```

Setting up the network and optimizer:

```julia:xor-setup
setup = [
    DenseLayer((2, 2), sigmoid_activation),
    DenseLayer((2, 2), sigmoid_activation)
]

xor_net = CreateNetwork(setup, datatype=Float32, init_distribution=Normal());

OptimizerSetup!(xor_net, GradientDescentOptimizer!, learning_rate=0.01)
```

\show{xor-setup}

Training loop:

```julia:xor-train
epochs = 250

xor_loss = 0.0
xor_losses = []

cross_entropy_loss(x_in, y_val) = -sum(y_val .* log.(Forward(xor_net, x_in)))

for epoch in 1:epochs
    for (i, input) in enumerate(data)
        x_in = convert(Vector{Float32}, input)
        y_val = targets[i]

        pred = Forward(xor_net, x_in)
        global xor_loss = cross_entropy_loss(x_in, y_val)

        Backward!(xor_net, cross_entropy_loss, x_in, y_val)

        if epoch % 50 == 0 && i == length(targets)
            println("Epoch $epoch\tPred: $(round(maximum(pred), digits=4))\tTarget: $(maximum(y_val))\tloss: $(round(xor_loss, digits=4))")
        end
    end
    push!(xor_losses, xor_loss)
end

preds = round.(maximum.([Forward(xor_net, convert(Vector{Float32}, x)) for x in data]))
passed = preds .== convert(Vector{Float32}, maximum.(targets))

println("\n$(sum(passed))/4 tests passed | Accuracy $(100 * sum(passed) / length(targets))%")
```

\show{xor-train}

```julia:xor-plot
plot(
    xor_losses,
    xlabel="Epoch", ylabel="Cross-Entropy Loss", label="",
    size=(800,500), dpi=300
)
savefig(joinpath(@OUTPUT, "xor-plot.svg")) # hide
```

@@im-100
\fig{xor-plot}
@@

## Comparing Optimizers

`simple_nn` has a couple of built-in optimizers. To compare them, we'll revisit the XOR problem. Defining the networks for each optimizer:

```julia:opt-setup
optimizers = [
    GradientDescentOptimizer!,
    MomentumOptimizer!,
    RMSpropOptimizer!,
    AdamOptimizer!
]

xor_networks = [
    CreateNetwork(setup, datatype=Float32, init_distribution=Normal()) for _ in 1:length(optimizers)
]

for (i, opt) in enumerate(optimizers)
    OptimizerSetup!(xor_networks[i], opt)
end
```

Training loop:

```julia:opt-train
opt_loss = []
opt_losses = []

loss_funcs = [
    (x_in, y_val) -> -sum(y_val .* log.(Forward(net, x_in))) for net in xor_networks
]

for epoch in 1:epochs
    for (i, input) in enumerate(data)
        x_in = convert(Vector{Float32}, input)
        y_val = targets[i]

        global opt_loss = []

        for i in 1:length(optimizers)
            push!(opt_loss, loss_funcs[i](x_in, y_val))
            Backward!(xor_networks[i], loss_funcs[i], x_in, y_val)
        end
    end
    push!(opt_losses, opt_loss)
end
```

Plotting the losses of each optimizer:

```julia:opt-plot
loss_gd = [loss[1] for loss in opt_losses]
loss_mgd = [loss[2] for loss in opt_losses]
loss_rms = [loss[3] for loss in opt_losses]
loss_adam = [loss[4] for loss in opt_losses]

plot(loss_gd, xlabel="Epoch", ylabel="Cross-Entropy Loss", label="Gradient Descent", size=(800,500), dpi=300)
plot!(loss_mgd, label="Momentum")
plot!(loss_rms, label="RMSprop")
plot!(loss_adam, label="ADAM")
savefig(joinpath(@OUTPUT, "opt-plot.svg")) # hide
```

@@im-100
\fig{opt-plot}
@@

## MNIST

Importing data:

```julia:mnist-data
train_x, train_y = MNIST(split=:train)[:]
train_x = Float32.(train_x)

test_x, test_y = MNIST(split=:test)[:]
test_x = Float32.(test_x)
```

Defining some helper functions:

```julia:mnist-helper
flatten(matrix) = vcat(matrix...)

function one_hot_encoding(target)
    return Float32.(target .== collect(0:9))
end
```

Defining the network:

```julia:mnist-net
mnist_network = CreateNetwork([
    DenseLayer((784, 128), sigmoid_activation),
    DenseLayer((128, 64), sigmoid_activation),
    DenseLayer((64, 10), softmax_activation)
], datatype=Float32, init_distribution=Normal())

OptimizerSetup!(mnist_network, AdamOptimizer!);
```

Training loop:

```julia:mnist-train
epochs = 1000

mnist_loss = 0.0

batch_size = 32
batch_losses = []
validation_accuracies = []

cross_entropy_loss(x_in, y_val) = -sum(y_val .* log.(Forward(mnist_network, x_in)))

for epoch in 1:epochs
    batch_idx = rand((1:size(train_x, 3)), batch_size)

    batch_x = train_x[1:end, 1:end, batch_idx]
    batch_y = train_y[batch_idx]

    batch_loss = []

    for i in 1:batch_size
        x_in = convert(Vector{Float32}, flatten(batch_x[1:end, 1:end, i]))
        y_val = one_hot_encoding(batch_y[i])

        pred = Forward(mnist_network, x_in)
        global mnist_loss = cross_entropy_loss(x_in, y_val)

        Backward!(mnist_network, cross_entropy_loss, x_in, y_val)

        push!(batch_loss, mnist_loss)
    end

    push!(batch_losses, sum(batch_loss) / length(batch_loss))

    if epoch % 5 == 0
        val_batch = 32
        val_batch_idx = rand((1:size(test_x, 3)), val_batch)

        test_predictions = argmax.([
            Forward(mnist_network, convert(Vector{Float32}, flatten(test_x[1:end, 1:end, idx]))) for idx in val_batch_idx
        ]) .- 1

        test_correct = test_predictions .== test_y[val_batch_idx]
        val_accuracy = 100 * sum(test_correct) / val_batch

        push!(validation_accuracies, val_accuracy)
    end
end
```

```julia:mnist-plot
p1 = plot(batch_losses, yaxis=:log, label="Batch Loss")
p2 = plot(validation_accuracies, label="Validation Accuracy")

plot(p1, p2, layout=(1,2), size=(800,400), dpi=300)
savefig(joinpath(@OUTPUT, "mnist-plot.svg")) # hide
```

@@im-100
\fig{mnist-plot}
@@

Classifying a small sample of images:

```julia:mnist-samp-plot
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
```

@@im-100
\fig{mnist-samp-plot}
@@

Overall accuracy:

```julia:mnist-acc
test_predictions = argmax.([
    Forward(mnist_network, convert(Vector{Float32}, flatten(test_x[1:end, 1:end, i]))) for i in 1:size(test_x, 3)
]) .- 1

test_correct = test_predictions .== test_y

println("Accuracy: $(round(100 * sum(test_correct) / length(test_correct), digits=2))%")
```

\show{mnist-acc}

## Wrapping Up

Hope you enjoyed this small showcase of `simple_nn`. I am planning on working on it some more. I already have a somewhat functional implementation of convolutional neural networks, but it does not work that well with `Zygote.jl`, the autodifferentiation library I use. I created this project for my own learning, I do not expect anyone to actually use this. But it was fun to work on, and it definitely helped me understand the neural networks a lot more.

Thanks for reading! Until next time.
