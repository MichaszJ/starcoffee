# This file was generated, do not modify it. # hide
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