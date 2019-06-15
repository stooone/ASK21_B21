-- B21
-- Trigger trim: set trim for aircraft to match current airspeed
-- Take current airspeed for range Min-Mid-Max and set trim dataref to +1 .. 0 .. -1

-- TRIM trigger calibration, must match aircraft for trigger trim to set accurately
TRIM_SPEED_KTS = { 45, 57, 84 } -- cruise speeds (knots) for trim range +1..0..-1

print("b21_trim starting")

-- WRITE datarefs
local dataref_trim = globalPropertyf("sim/cockpit2/controls/elevator_trim") -- -1.0 .. +1.0
-- READ datarefs
local dataref_airspeed_kts = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec")
-- 

local sound_trim = loadSample(sasl.getAircraftPath()..'/sounds/systems/trim.wav')
setSampleGain(sound_trim, 500)

local prev_click_time_s = 0.0 -- time button was previously clicked (so only one action per click)
local current_trim = 0.0
local required_trim = 0.0
local prev_trim_time_s = 0.0

local command_trim = sasl.createCommand("b21/trim/trigger", 
    "Sailplane elevator trim set immediately to current speed")

function clicked_trim(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and phase == SASL_COMMAND_BEGIN
    then
        print("CLICKED TRIM, current_trim = "..current_trim)
        prev_click_time_s = get(dataref_time_s)

        playSample(sound_trim, false)

        local Smin = TRIM_SPEED_KTS[1]
        local Szero = TRIM_SPEED_KTS[2]
        local Smax = TRIM_SPEED_KTS[3]
        
        local S = get(dataref_airspeed_kts) -- current speed

        if S < Smin
        then
            required_trim = 1.0                           -- i.e. set +1
        elseif S < Szero
        then
            required_trim = (Szero - S) / (Szero - Smin)  -- i.e. set +1 .. 0
        elseif S < Smax
        then
            required_trim = (Szero - S)/(Smax - Szero)    -- i.e. set 0 .. -1
        else
            required_trim = -1.0                          -- i.e. set -1
        end
        --print("required trim set to",required_trim)
    end
    return 1
end

sasl.registerCommandHandler(command_trim, 0, clicked_trim)

local TRIM_PER_SECOND = 1.0 -- amount of trim smoothing

-- update the actual trim setting gradually
function update()
    local time_now_s = get(dataref_time_s)
    local time_delta_s = time_now_s - prev_trim_time_s
    local trim_delta = required_trim - current_trim
    -- print("time_delta_s = "..time_delta_s)
    if  time_delta_s > 0.5 -- update 10 per second max
    then
        --print("update trim trim_delta="..trim_delta)
        if  math.abs(trim_delta) > 0.05
        then
            --print("time_delta",time_delta_s, current_trim, trim_delta)
            current_trim = current_trim + trim_delta * time_delta_s * TRIM_PER_SECOND
            print("new trim", current_trim)
            if current_trim > 1.0
            then
                current_trim = 1.0
            elseif current_trim < -1.0
            then
                current_trim = -1.0
            end
            set(dataref_trim, current_trim)
        end
        prev_trim_time_s = time_now_s
    end
end
