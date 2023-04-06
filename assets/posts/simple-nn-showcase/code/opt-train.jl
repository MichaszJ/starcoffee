# This file was generated, do not modify it. # hide
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