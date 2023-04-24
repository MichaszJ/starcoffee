# This file was generated, do not modify it. # hide
rate_axis = (
    xticklabelrotation=π/4,
    xlabel="",
    ylabel="Success Rate (%)",
)

rate_order = rate_data.Rocket_Organisation

rate_layers = data(rate_data) *
    mapping(:Rocket_Organisation => sorter(rate_order), :Success_Rate)

rate_fig = draw(rate_layers; axis=rate_axis)

save("assets/posts/visualizing-rocket-data/code/rate.svg", rate_fig) #hide