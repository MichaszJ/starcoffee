# This file was generated, do not modify it. # hide
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