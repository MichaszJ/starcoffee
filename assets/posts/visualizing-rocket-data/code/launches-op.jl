# This file was generated, do not modify it. # hide
@chain launch_data begin
    @group_by(Rocket_Organisation)
    @summarize(Launches = nrow())
    @filter(Launches > 140)
    @arrange(desc(Launches))
end