@def title = "Rocket Launch Industry Data Visualizations"
@def published = "April 24th, 2023"
@def tags = ["Julia", "Programming", "Aerospace", "Blogging", "Data Visualization"]

<!-- @def reeval = true -->

# Rocket Launch Industry Data Visualizations

_By Michal Jagodzinski - April 24th, 2023_

\tableofcontents

@@im-100
![](https://source.unsplash.com/qdBLpTGXPas)
@@

@@img-caption
Photo by [Wolfgang Hasselmann](https://unsplash.com/photos/qdBLpTGXPas)
@@

Hello and welcome back to Star Coffee! I'm delving into a new topic today, data visualization using Julia. I am going to be visualizing some data about the rocket launch industry using `AlgebraOfGraphics.jl`, a [Grammar of Graphics](https://www.amazon.com/Grammar-Graphics-Statistics-Computing/dp/0387245448/) visualization library build on top of `Makie.jl`. To do various data operations, I will be using `Tidier.jl`, a library built on top of `DataFrames.jl` to bring [tidyverse](https://www.tidyverse.org/)-style data manipulation to Julia.

`AlgebraOfGraphics.jl` is based on [The Grammar of Graphics](https://www.amazon.com/Grammar-Graphics-Statistics-Computing/dp/0387245448/), a methodology for creating quantitative graphics. `AlgebraOfGraphics` is very similar to [R's ggplot2](https://ggplot2.tidyverse.org/) library. I've used ggplot2 before various times, and it is incredible how easy it is to make some complex visualizations using it, and I'm glad the Julia ecosystem has an equivalent plotting library.

I am writing this post as I wanted to test out the capabilities of both `AlgebraOfGraphics.jl` and `Tidier.jl`. I have been interested in checking out both libraries for a bit now, but I haven't gotten the opportunity to. Lately I've been trying to improve my data visualization skills, so I decided to try these libraries out to visualize some interesting data. I'm also interested to see how `AlgebraOfGraphics.jl` stacks up to my preferred data visualization tool, [ggplot2](https://ggplot2.tidyverse.org/).

Data source: [Rocket Launch Industry](https://www.kaggle.com/datasets/maccaroo/rocket-launch-industry) on Kaggle.

## Looking at the Data

Importing required libraries:

```julia:imports
using AlgebraOfGraphics, CairoMakie, Tidier, DataFrames, CSV
set_aog_theme!()
```

Importing the data and getting an overview:

```julia:launch-data
launch_data = CSV.read("./data/Launches.csv", DataFrame)
describe(launch_data)
```

\show{launch-data}

It's always good to do a preliminary analysis of the data to get some insights. For instance, we can see the latest date in this dataset is December 12th, 2021, meaning we are missing over a year's worth of data as of writing. We can also see some columns have significant numbers of missing values, something we'll need to account for when doing some data operations.

First, I'll rename some columns to work better with `Tidier` and `AlgebraOfGraphics`:

```julia:rename
rename!(launch_data,
    "Rocket Organisation" => :Rocket_Organisation,
    "Launch Status" => :Launch_Status,
    "USD/kg to LEO" => :USD_kg_to_LEO,
    "Rocket Price" => :Rocket_Price,
    "Rocket Payload to LEO" => :Rocket_Payload,
    "Rocket Price CPI Adjusted" => :Rocket_Price_Adjusted
);
```

Let's visualize the number of launches grouped by the launch organisation. Before visualizing, let's take a closer look at some specific parts of the data. Let's see how many launch organisations are included in this dataset:

```julia:orgs
size(unique(launch_data.Rocket_Organisation))
```

\show{orgs}

There are 55 different organisations listed in this dataset, so we'll need to filter most out to ensure our visualization doesn't end up a hard-to-read mess. Next, let's use `Tidier` to count the number of launches by organisation and filter the ones with more than 140 launches (giving us a round 10 organisations):

```julia:launches-op
@chain launch_data begin
    @group_by(Rocket_Organisation)
    @summarize(Launches = nrow())
    @filter(Launches > 140)
    @arrange(desc(Launches))
end
```

\show{launches-op}

That's a lot of rockets, especially from the USSR. Next let's get a filtered version of the data for plotting, as well as the ordered vector of launch organisations:

```julia:launches-data
nlaunch_data = @chain launch_data begin
    @group_by(Rocket_Organisation)
    @mutate(n = nrow())
    @filter(n > 140)
    @filter(Launch_Status != "Prelaunch Failure")
    @ungroup
    @arrange(desc(n))
end

nlaunch_order = @chain launch_data begin
    @group_by(Rocket_Organisation)
    @summarize(n = nrow())
    @filter(n > 140)
    @arrange(desc(n))
end

nlaunch_order = Vector{String}(
    nlaunch_order.Rocket_Organisation
)
```

## Creating the First Visualization

Finally, let's visualize this data using the `filtered_data` DataFrame:

```julia:launches-viz
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
```

@@im-75
\fig{launches}
@@

Now it's a lot more evident just the sheer magnitude of rockets the USSR has launched based on this visualization. Also notice the lack of failures for ULA.

In contrast, here's the equivalent plot made with ggplot:

```r
organisation_vector <- launch_data %>%
    group_by(Rocket_Organisation) %>%
    summarize(Launches=n()) %>%
    arrange(desc(Launches)) %>%
    head(10) %>%
    pull(Rocket_Organisation)

fig1_data <- launch_data %>%
    mutate(
        Rocket_Organisation=factor(Rocket_Organisation, levels=organisation_vector),
        Launch_Status=factor(Launch_Status, levels=c("Success", "Partial Failure", "Failure")),
    ) %>%
    group_by(Rocket_Organisation, Launch_Status) %>%
    count(Launch_Status, .drop=FALSE) %>%
    filter(Rocket_Organisation %in% organisation_vector) %>%
    filter(Launch_Status != "Prelaunch Failure")


fig1 <- ggplot(data=fig1_data, aes(x=Rocket_Organisation, y=n, fill=Launch_Status)) +
    geom_col() +
    facet_grid(Launch_Status~., scales = "free") +
    theme_minimal() +
    labs(
        title="Launches of Major Rocket Organisations",
        subtitle="Number of launches by launch status from 1957 to 2021",
        caption="Data compiled by Maciej Krzysik on Kaggle",
        y="Number of Launches (1957 - 2021)"
    ) +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 45, hjust = 1),
        panel.grid.major = element_blank(),
        axis.title.x = element_blank(),
    ) +
    scale_fill_manual(values=c("#003f5c", "#ffa600", "#ff6361"))

fig1
```

@@im-75
\fig{ggplot-fig1}
@@

Unfortunately, I could not replicate a caption on the `AlgebraOfGraphics.jl` version of this visualization that looked decent.

## Diving Deeper

Let's take a closer look at the visualization code to see what's happening. First, we define an `axis` tuple to set some axis-specific options:

```julia
fig1_axis = (
    xticklabelrotation=π/4,
    xlabel="",
    ylabel="Number of Launches (1957 - 2021)",
)
```

Next, we define some vectors to specify the appearance order of the colours, or the `Launch_Status` column. I wanted the subplots in a specific order instead of the default one, and the `color_sort` vector is used to specify that order. Then, I define a vector of custom colours for each value of `Launch_Status`.

```julia
color_sort = ["Success", "Partial Failure", "Failure"]
colors = [colorant"#003f5c", colorant"#ffa600", colorant"#ff6361"]
```

Next, we define the `AlgebraOfGraphics` figure. First, the data source is specified, in this case the `nlaunch_data` DataFrame:

```julia
fig1_layers = data(nlaunch_data)
```

Next we define the initial mapping of the data, concatenating the `fig1_layers` variable using the `*` operator. You can think of mappings as specifying which parts of the data control specific parts of the resulting plot. We want to produce a bar plot showing the frequency of launches by the rocket organisation, so we set the `Rocket_Organisation` as the independent variable by using it as the first positional argument to the `mapping` function. We can order mappings using the `sorter` function, which takes an iterable object as input. This is why I defined the `nlaunch_order` variable earlier, as by default the values are ordered alphabetically.

```julia
fig1_layers = data(nlaunch_data) *
    mapping(
        :Rocket_Organisation => sorter(nlaunch_order))
```

Next, we define more mappings. I want the colours of the plot to correspond to the `Launch_Status`, so I map `color` to that column. I then sort the `color` mapping by the `colour_sort`, I want to make sure the colours of the `Launch_Status` values are in the order of my custom colours. I then rename the title for the mapping, as otherwise the legend would display "Launch_Status".

```julia
fig1_layers = data(nlaunch_data) *
    mapping(
        :Rocket_Organisation => sorter(nlaunch_order),
        color=:Launch_Status => sorter(colour_sort) => "Launch Status")
```

Next, we break the plot apart into three rows of subplots based on the `Launch_Status` using the `row` mapping. Alternatively, we could've split the plot into three separate columns using the `col` mapping. Again, I sort the mapping using the `colour_sort` variable to ensure the `Success` status comes first and the `Failure` last.

```julia
fig1_layers = data(nlaunch_data) *
    mapping(
        :Rocket_Organisation => sorter(nlaunch_order),
        color=:Launch_Status => sorter(colour_sort) => "Launch Status",
        row=:Launch_Status => sorter(colour_sort))
```

To complete our figure, we concatenate the visual layer we are using. In this case, we want a `frequency` plot:

```julia
fig1_layers = data(nlaunch_data) *
    mapping(
        :Rocket_Organisation => sorter(nlaunch_order),
        color=:Launch_Status => sorter(colour_sort) => "Launch Status",
        row=:Launch_Status => sorter(colour_sort)) *
    frequency()
```

Finally we draw the image. When working with `AlgebraOfGraphics.jl`, you normally don't need to initialize a `Figure`. However, the normal way of defining `AlgebraOfGraphics.jl` plots automatically generates a legend and adds any `title` or `subtitle` defined in the `axis` tuple to be included in each subplot. The next visualizations I'll showcase do not include this, and are more representative of the "normal" way to make plots with `AlgebraOfGraphics.jl`.

```julia
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
```

Just for reference, here is how the plot would look like if I did not do these extra steps (i.e. the "normal" way):

```julia:launches-scuffed
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
```

@@im-75
\fig{launches-scuffed}
@@

Yeah, not the greatest plot. The extra titles and legend are unnecessary. But the extra work to fix these problems is not too bad.

## Some More Visualizations

Here are a couple more visualizations. I won't go too in-depth in the code this time around.

### Organisation Rate of Failure Visualization

Let's look at the launch statuses a bit more. We can analyze the success rates of the organisations with the most launches, the same ones for the last visualization.

```julia:rate-op
rate_data = @chain launch_data begin
    @group_by(Rocket_Organisation)
    @summarize(
        Launches = nrow(),
        Success = sum(Launch_Status .== "Success")
    )
    @filter(Success > 133)
    @mutate(Success_Rate = 100*Success/Launches)
    @arrange(desc(Success_Rate))
end
```

\show{rate-op}

```julia:rate-viz
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
```

@@im-75
\fig{rate}
@@

Unfortunately, this visualization really did not turn out the way I wanted. It seems `AlgebraOfGraphics.jl` currently does not support making arbitrary bar graphs, only frequency plots/histograms. The `ggplot` visualization shows what I was going for:

```r
options(repr.plot.width = 8, repr.plot.height = 5, repr.plot.res=300)

fig2_order <- launch_data %>%
    filter(Rocket_Organisation %in% organisation_vector) %>%
    group_by(Rocket_Organisation) %>%
    summarize(Launches = n(), Success = sum(Launch_Status == "Success")) %>%
    mutate(Success_Rate = 100*Success/Launches) %>%
    arrange(desc(Success_Rate)) %>%
    pull(Rocket_Organisation)

fig2_data <- launch_data %>%
    filter(Rocket_Organisation %in% organisation_vector) %>%
    mutate(Rocket_Organisation=factor(Rocket_Organisation, levels=fig2_order)) %>%
    group_by(Rocket_Organisation) %>%
    summarize(Launches = n(), Success = sum(Launch_Status == "Success")) %>%
    mutate(Success_Rate = 100*Success/Launches) %>%
    arrange(desc(Success_Rate))

fig2 <- ggplot(data=fig2_data, aes(x=Rocket_Organisation, y=Success_Rate)) +
    geom_col(fill="#003f5c") +
    ggtext::geom_textbox(
        aes(label = paste0(round(Success_Rate, digits = 1), "%")),
        size = 3,
        halign = 0.5,
        vjust=1,
        box.colour = NA,
        fill = NA,
        colour = "#FFFFFF",
        fontface = "bold"
    ) +
    theme_minimal() +
    labs(
        title="Launch Success Rates of Major Rocket Organisations",
        subtitle="Success rates of launches from 1957 to 2021",
        caption="Data compiled by Maciej Krzysik on Kaggle",
        y="Launch Success Rate (%)",
        x=""
    ) +
    theme(
        axis.text.x = element_text(angle = 45, hjust = 0.75),
        panel.grid.major.x = element_blank(),
    )

fig2
```

@@im-100
\fig{ggplot-fig2}
@@

### Rocket Payload and Cost Visualization

Next, let's look at the relationship between each organisation's mean rocket cost and mean payload. First, we again take an initial look at the data to see what kinds of numbers we're working with:

```julia:cost-op
cost_launch_data = @chain launch_data begin
    @group_by(Rocket_Organisation)
    @summarize(
        Launches = nrow(),
        Mean_Price = mean(skipmissing(Rocket_Price_Adjusted)),
        Mean_Payload = mean(skipmissing(Rocket_Payload))
    )
    @filter(!isnan(Mean_Price) .&& !isnan(Mean_Payload))
    @arrange(desc(Mean_Price))
end
```

\show{cost-op}

Next, we can visualize this data, and add some text annotations to this visualization:

```julia:cost-viz
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
```

@@im-75
\fig{costs}
@@

And now for a `ggplot` version:

```r
fig3_data <- launch_data %>%
    group_by(Rocket_Organisation) %>%
    summarize(
        Launches=n(),
        Mean_Payload=mean(Rocket_Payload, na.rm = TRUE),
        Mean_Price_Adjusted=1e6 * mean(Rocket_Price_Adjusted, na.rm = TRUE),
        Mean_USD_Kg_Adjusted=mean(USD_Kg_Adjusted, na.rm=TRUE)
    ) %>%
    drop_na

fig3 <- ggplot(data=fig3_data, aes(x=Mean_Payload, y=Mean_Price_Adjusted)) +
    geom_point(aes(color=Mean_USD_Kg_Adjusted, size=Mean_USD_Kg_Adjusted)) +
    ggrepel::geom_text_repel(
        aes(label=Rocket_Organisation, color=Mean_USD_Kg_Adjusted),
        size = 2.25,
        min.segment.length = 0,
        box.padding = unit(0.5, "lines"),
        family="JuliaMono"
    ) +
    scale_x_log10() +
    scale_y_log10() +
    scale_colour_gradientn(
        colours=c("#003f5c", "#ff6361"),
    ) +
    labs(
        title="Mean Rocket Price and Payload Mass of Rocket Organisations",
        subtitle="Based on data from 1957 to 2021 adjusted for inflation in 2021",
        caption="Data compiled by Maciej Krzysik on Kaggle",
        y="Mean Rocket Price ($USD)",
        x="Mean Payload Mass (kg)",
        colour="Mean $USD/kg"
    ) +
    theme_minimal() +
    guides(
        color=guide_colorbar(
            title.position = "top",
            title.hjust = .5,
            barwidth=unit(20, "lines"),
            barheight=unit(.5, "lines"),

        ),
        size = "none")+
    theme(
        legend.position = "top",
        text = element_text(family = "JuliaMono"),
        plot.title = ggtext::element_textbox_simple(
            margin = margin(0, 0, 0.5, 0, "lines"),
            face = "bold"
        ),
        plot.subtitle = ggtext::element_textbox_simple(
            size = rel(0.75),
            margin = margin(0, 0, 0.5, 0, "lines")
        ),
        plot.caption = ggtext::element_textbox_simple(
            size = rel(0.75),
            margin = margin(1, 0, 0, 0, "lines"),
            halign=1
        ),

    ) +
    coord_cartesian(expand=FALSE, clip="off")

fig3
```

@@im-100
\fig{ggplot-fig3}
@@

Ok, I might have gotten extra with this one. But I think it's a interesting visualization, so I wanted to make sure it looked nice. The text annotation in `AlgebraOfGraphics.jl` cannot compare at all to the `ggrepel` library. It allows us to quickly make annotations that automatically space out. Whereas for the `AlgebraOfGraphics.jl`, I could not make the same annotations automatically without lots of unreadable text boxes, and had to manually add a select few annotations with adjustments.

## Conclusion

In summary, while `AlgebraOfGraphics.jl` does not have the same level of features and maturity as `ggplot2`, it still is a very usable data visualization library. In addition, since `AlgebraOfGraphics.jl` is built on top of `Makie.jl`, users have low-level access to the plotting backend, allowing for greater customizability compared to `ggplot2`. I am excited to see the evolution of `AlgebraOfGraphics.jl` as it matures.

In regard to `Tidier.jl`, I am seriously impressed with the speed with which this library was developed, and the level of usability it already has. It was easy to pick up with my background of using the `tidyverse` for data manipulation previously, and in general it is an intuitive library to use.

Thanks for reading! I hope you learned a bit about using `AlgebraOfGraphics.jl` and/or `ggplot`. I hope my quick visualizations look decent enough. More posts coming soon. Until next time.
