# This file was generated, do not modify it. # hide
using CairoMakie, AlgebraOfGraphics
using ModelingToolkit, ModelingToolkitStandardLibrary
using DifferentialEquations
set_aog_theme!()

@parameters t
const B = ModelingToolkitStandardLibrary.Blocks