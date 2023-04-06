# This file was generated, do not modify it. # hide
mnist_network = CreateNetwork([
    DenseLayer((784, 128), sigmoid_activation),
    DenseLayer((128, 64), sigmoid_activation),
    DenseLayer((64, 10), softmax_activation)
], datatype=Float32, init_distribution=Normal())

OptimizerSetup!(mnist_network, AdamOptimizer!);