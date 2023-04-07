# This file was generated, do not modify it. # hide
@variables(begin
    t, [unit=u"s"],
    x₁(t), [unit=u"m"],
    y₁(t), [unit=u"m"],
    z₁(t), [unit=u"m"],
    ẋ₁(t), [unit=u"m/s"],
    ẏ₁(t), [unit=u"m/s"],
    ż₁(t), [unit=u"m/s"],
    x₂(t), [unit=u"m"],
    y₂(t), [unit=u"m"],
    z₂(t), [unit=u"m"],
    ẋ₂(t), [unit=u"m/s"],
    ẏ₂(t), [unit=u"m/s"],
    ż₂(t), [unit=u"m/s"],
    x₃(t), [unit=u"m"],
    y₃(t), [unit=u"m"],
    z₃(t), [unit=u"m"],
    ẋ₃(t), [unit=u"m/s"],
    ẏ₃(t), [unit=u"m/s"],
    ż₃(t), [unit=u"m/s"],
    r₁₂(t), [unit=u"m"],
    r₁₃(t), [unit=u"m"],
    r₂₃(t), [unit=u"m"]
end)

D = Differential(t)

@parameters G [unit=u"N*m^2/kg^2"] m₁ [unit=u"kg"] m₂ [unit=u"kg"] m₃ [unit=u"kg"]