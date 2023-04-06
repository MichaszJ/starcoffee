# This file was generated, do not modify it. # hide
setup = [
    DenseLayer((2, 2), sigmoid_activation),
    DenseLayer((2, 2), sigmoid_activation)
]

xor_net = CreateNetwork(setup, datatype=Float32, init_distribution=Normal());

OptimizerSetup!(xor_net, GradientDescentOptimizer!, learning_rate=0.01)