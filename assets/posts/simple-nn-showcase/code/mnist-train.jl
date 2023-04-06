# This file was generated, do not modify it. # hide
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