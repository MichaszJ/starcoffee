# This file was generated, do not modify it. # hide
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