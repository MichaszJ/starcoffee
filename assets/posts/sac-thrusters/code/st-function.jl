# This file was generated, do not modify it. # hide
global_switch = 0

function _schmitt_behaviour_model(u, U_on, U_off; total_torque=1)
    global global_switch

    clamped_u = clamp(u/total_torque, -1, 1)

    if sign(clamped_u) > 0
        if clamped_u ≥ U_on && global_switch == 0
            global_switch = 1
        elseif clamped_u ≤ U_off && global_switch == 1
            global_switch = 0
        end
    else
        if clamped_u ≤ -U_on && global_switch == 0
            global_switch = -1
        elseif clamped_u ≥ -U_off && global_switch == -1
            global_switch = 0
        end
    end

    return global_switch
end

@register_symbolic _schmitt_behaviour_model(u, U_on, U_off)