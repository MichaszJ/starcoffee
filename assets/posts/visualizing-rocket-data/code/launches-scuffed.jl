# This file was generated, do not modify it. # hide
fig1_scuffed_axis = (
    width = 500,
    height = 200,
    xticklabelrotation=π/4,
    xlabel="",
    ylabel="Number of Launches",
    title="Launches of Major Rocket Organisations",
    subtitle="Number of launches by launch status from 1957 to 2021"
)

fig1_scuffed = draw(
    fig1_layers;
    axis=fig1_scuffed_axis,
    facet=(; linkyaxes=:none),
    palettes=(; color=colours)
)

save("assets/posts/visualizing-rocket-data/code/launches-scuffed.svg", fig1_scuffed) #hide