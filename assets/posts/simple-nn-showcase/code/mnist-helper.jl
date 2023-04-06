# This file was generated, do not modify it. # hide
flatten(matrix) = vcat(matrix...)

function one_hot_encoding(target)
    return Float32.(target .== collect(0:9))
end