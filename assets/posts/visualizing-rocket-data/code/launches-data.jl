# This file was generated, do not modify it. # hide
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