# This file was generated, do not modify it. # hide
function remove_units(p::Dict)
    Dict(k => Unitful.ustrip(ModelingToolkit.get_unit(k), v) for (k, v) in p)
end