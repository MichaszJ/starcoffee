# This file was generated, do not modify it. # hide
using Random, LinearAlgebra, Distributions, CairoMakie

# custom plot styling
CairoMakie.activate!(type = "svg")
set_theme!(theme_minimal())

gray_val = 150
gray_col = Makie.RGB(gray_val/255, gray_val/255, gray_val/255)

update_theme!(
    fonts = (; regular = "JuliaMono-Light", bold = "JuliaMono-Light"),
    Axis = (
        leftspinevisible = true,
        rightspinevisible = false,
        bottomspinevisible = true,
        topspinevisible = false,
        leftspinecolor = gray_col,
        bottomspinecolor = gray_col,
        xtickcolor = gray_col,
        xticksvisible = true,
        xminorticksvisible = true,
        xminortickcolor = gray_col,
        ytickcolor = gray_col,
        yticksvisible = true,
        yminorticksvisible = true,
        yminortickcolor = gray_col,
        xminortickalign = 1.0,
        xtickalign = 1.0,
        yminortickalign = 1.0,
        ytickalign = 1.0,
        yticksize=7, xticksize=7,
        yminorticksize=5, xminorticksize=5,
        xticklabelsize=13.0f0, yticklabelsize=13.0f0
    )
)