-- B21
-- Trigger trim: set trim for aircraft to match current airspeed
-- Take current airspeed for range Min-Mid-Max and set trim dataref to +1 .. 0 .. -1

print("b21_trim starting, TRIM_SPEEDS_KTS =", 
        project_settings.TRIM_SPEEDS_KTS[1], -- cruise speed with trim fully back (Min)
        project_settings.TRIM_SPEEDS_KTS[2], -- cruise speed trim zero (Mid)
        project_settings.TRIM_SPEEDS_KTS[3]) -- cruise speed trim fully forwards (Max)

-- WRITE datarefs
local dataref_trim = globalPropertyf("sim/cockpit2/controls/elevator_trim") -- -1.0 .. +1.0
-- READ datarefs
local dataref_airspeed_kts = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec")
-- 
local prev_click_time_s = 0.0 -- time button was previously clicked (so only one action per click)

local command_trim = sasl.createCommand("b21/trim/trigger", 
    "Sailplane elevator trim set immediately to current speed")

function clicked_trim(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and phase == SASL_COMMAND_BEGIN
    then
        print("CLICKED TRIM")
        prev_click_time_s = get(dataref_time_s)

        local Smin = project_settings.TRIM_SPEEDS_KTS[1]
        local Szero = project_settings.TRIM_SPEEDS_KTS[2]
        local Smax = project_settings.TRIM_SPEEDS_KTS[3]
        
        local S = get(dataref_airspeed_kts) -- current speed

        if S < Smin
        then
            set(dataref_trim, 1.0)                         -- i.e. set +1
        elseif S < Szero
        then
            set(dataref_trim, (Szero - S) / (Szero - Smin)) -- i.e. set +1 .. 0
        elseif S < Smax
        then
            set(dataref_trim, (S - Smax)/(Smax - Szero))    -- i.e. set 0 .. -1
        else
            set(dataref_trim, -1.0)                          -- i.e. set -1
        end
        print("b21_trim set to",get(dataref_trim))
    end
    return 1
end

sasl.registerCommandHandler(command_trim, 0, clicked_trim)
    