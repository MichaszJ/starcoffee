# This file was generated, do not modify it. # hide
train_x, train_y = MNIST(split=:train)[:]
train_x = Float32.(train_x)

test_x, test_y = MNIST(split=:test)[:]
test_x = Float32.(test_x)