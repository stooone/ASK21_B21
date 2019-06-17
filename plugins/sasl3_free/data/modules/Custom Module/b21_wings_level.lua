-- B21
-- Wings level

print("b21_wings_level starting")

-- WRITE datarefs
local DATAREF_ROLL_NM = globalPropertyf("sim/flightmodel/forces/L_plug_acf") -- Newton-meters, +ve is right-roll
-- READ datarefs
local DATAREF_ROLL_DEG = globalPropertyf("sim/flightmodel/position/true_phi")
local DATAREF_GROUNDSPEED_MS = globalPropertyf("sim/flightmodel/position/groundspeed")
local DATAREF_ONGROUND = globalPropertyi("sim/flightmodel/failures/onground_any") -- =1 when on the ground
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec")
-- 

local WING_LEVELLER_FORCE = 1000.0 -- newton-meters

--local sound_trim = loadSample(sasl.getAircraftPath()..'/sounds/systems/trim.wav')
-- setSampleGain(sound_trim, 500)

local command_wings_level_on = sasl.createCommand("b21/wings_level_on", 
    "Start level aircraft wings (e.g. sailplane)")
local command_wings_level_off = sasl.createCommand("b21/wings_level_off", 
    "Stop level aircraft wings (e.g. sailplane)")

local wings_level_running = 0

function wings_level_on(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("WINGS_LEVEL_ON COMMAND")
        wings_level_running = 1
    end
    return 1
end

function wings_level_off(phase)
    if phase == SASL_COMMAND_BEGIN
    then
        print("WINGS_LEVEL_OFF COMMAND")
        wings_level_running = 0
    end
    return 1
end

sasl.registerCommandHandler(command_wings_level_on, 0, wings_level_on)
sasl.registerCommandHandler(command_wings_level_off, 0, wings_level_off)

-- apply a rotational force to aircraft while wings_level_running = 1 and roll not zero
function update()
    if wings_level_running == 1
    then
        if get(DATAREF_ONGROUND) ~= 1 -- wings can only be levelled while on ground
           or get(DATAREF_GROUNDSPEED_MS) > 3.0 -- assume wings levelled up to 3 m/s (~6 knots)
        then
            print("WINGS_LEVEL AUTOCANCEL")
            wings_level_running = 0 -- if airborn or rolling fast then cancel wings_level
        else
            local roll_now_deg = get(DATAREF_ROLL_DEG)
            local lift_force = -roll_now_deg * WING_LEVELLER_FORCE / 10.0 -- make lift force proportional to required move
            --print("FORCE="..lift_force)
            local force_now_nm = get(DATAREF_ROLL_NM)
            set(DATAREF_ROLL_NM, force_now_nm + lift_force)
        end
    end
end
