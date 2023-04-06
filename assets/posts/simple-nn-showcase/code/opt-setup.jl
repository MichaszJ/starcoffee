# This file was generated, do not modify it. # hide
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