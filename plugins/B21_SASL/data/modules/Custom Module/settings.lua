-- B21

print("ASK21 Loading Settings")

-- HERE YOU CAN MODIFY SETTINGS FOR THIS AIRCRAFT

local VARIO_UNITS = 0   -- panel display units for variometers (0: knots, 1: m/s)
local SPEED_UNITS = 0   -- panel display units for air speed indicator (0: knots, 1: km/h)
local ALTITUDE_UNITS = 0 -- panel display units for altimeter (0: feet, 1: meters)

project_settings.QUIET_CLIMB = 100 -- vario climb sound muted below 100 fpm (~1 knot, 0.5 m/s)
project_settings.QUIET_SINK = -150 -- vario sink sound muted above 150 fpm (~1.5 knot, 0.75 m/s)
project_settings.VARIO_VOLUME = 500 -- vario sound volume, set to 0 to mute
project_settings.VARIO_302_MODE = 1 -- choose initial operating mode for the 302 vario (0: stf, 1: auto, 2: te)

-- DON'T CHANGE ANYTHING BELOW HERE

-- put these values into DataRefs so they can be read by gauges
createGlobalPropertyi("b21/ask21/units_vario",VARIO_UNITS,false,true,true)
createGlobalPropertyi("b21/ask21/units_speed",SPEED_UNITS,false,true,true)
createGlobalPropertyi("b21/ask21/units_altitude",ALTITUDE_UNITS,false,true,true)