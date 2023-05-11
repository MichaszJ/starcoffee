# This file was generated, do not modify it. # hide
using CairoMakie, AlgebraOfGraphics, Latexify
using ModelingToolkit, ModelingToolkitStandardLibrary
using DifferentialEquations
set_aog_theme!()

@parameters t
const Rot = ModelingToolkitStandardLibrary.Mechanical.Rotational
const B = ModelingToolkitStandardLibrary.Blocks