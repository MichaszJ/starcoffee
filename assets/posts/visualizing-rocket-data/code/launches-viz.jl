# This file was generated, do not modify it. # hide
fig1_axis = (
    xticklabelrotation=π/4,
    xlabel="",
    ylabel="Number of Launches",
)

colour_sort = ["Success", "Partial Failure", "Failure"]
colours = [colorant"#003f5c", colorant"#ffa600", colorant"#ff6361"]

fig1_layers = data(nlaunch_data) *
    mapping(
        :Rocket_Organisation => sorter(nlaunch_order),
        color=:Launch_Status => sorter(colour_sort) => "Launch Status",
        row=:Launch_Status => sorter(colour_sort)) *
    frequency()

fig1 = Figure(resolution=(800,800))

title_ax = Axis(
    fig1[1,1],
    title="Launches of Major Rocket Organisations",
    subtitle="Number of launches by launch status from 1957 to 2021"
)
hidedecorations!(title_ax)

draw!(
    fig1,
    fig1_layers;
    axis=fig1_axis,
    facet=(; linkyaxes=:none),
    palettes=(; color=colours)
)

save("assets/posts/visualizing-rocket-data/code/launches.svg", fig1) #hide