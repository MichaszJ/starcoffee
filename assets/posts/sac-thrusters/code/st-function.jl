# This file was generated, do not modify it. # hide
global_switch = 0

function _schmitt_behaviour_model(u, U_on, U_off)
    global global_switch

    if sign(u) > 0
        if u ≥ U_on && global_switch == 0
            global_switch = 1
        elseif u ≤ U_off && global_switch == 1
            global_switch = 0
        end
    else
        if u ≤ -U_on && global_switch == 0
            global_switch = -1
        elseif u ≥ -U_off && global_switch == -1
            global_switch = 0
        end
    end

    return global_switch
end

@register_symbolic _schmitt_behaviour_model(u, U_on, U_off)