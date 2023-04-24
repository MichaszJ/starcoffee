# This file was generated, do not modify it. # hide
costs_axis = (
    width = 600, height = 500,
    xlabel="Mean Payload Mass (kg)",
    ylabel="Mean Price (\$USD)",
    title="Mean Rocket Price vs. Mean Payload Mass of Major Rocket Organisations",
    subtitle="Based on launches from 1957 to 2021 adjusted for 2021 inflation",
    yscale=log10,
    xscale=log10
)

costs_payload_fig = data(cost_launch_data) *
    mapping(:Mean_Payload, :Mean_Price => (p -> p*1e6))

fig2 = draw(
    costs_payload_fig;
    axis=costs_axis
)

text_x = [29072.4, 12259.1, 1598.17, 21425.7, 204.0, 300.0, 14840.9+8e3, 4470.67]
text_y = [1493.912951, 177.138444, 478.532254, 57.578071, 2.558725, 7.851438, 166.744533, 43.667909] .* 1e6
text = ["NASA", "ULA", "US Air Force", "SpaceX", "Astra", "Rocket Lab", "Arianespace", "ESA"]

# adding all organisations
# text!(
#     Float64.(cost_launch_data.Mean_Payload),
#     Float64.(cost_launch_data.Mean_Price);
#     text=Vector{String}(cost_launch_data.Rocket_Organisation),
#     align=(:center, :bottom)
# )

text!(
    text_x,
    text_y;
    text=text,
    align=(:center, :bottom)
)

save("assets/posts/visualizing-rocket-data/code/costs.svg", fig2) #hide