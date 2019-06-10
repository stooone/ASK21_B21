-- B21

print("ASK21 Loading Settings")

-- HERE YOU CAN MODIFY SETTINGS FOR THIS AIRCRAFT

-- UNITS for panel instuments, i.e. feet, meters etc
project_settings.VARIO_UNITS = 0   -- panel display units for variometers (0=knots, 1=m/s)
project_settings.SPEED_UNITS = 0   -- panel display units for air speed indicator (0=knots, 1=km/h)
project_settings.ALTITUDE_UNITS = 0 -- panel display units for altimeter (0=feet, 1=meters)
project_settings.DISTANCE_UNITS = 1 -- panel display units for computer (0=mi, 1=km)

-- VARIOMETER settings
project_settings.QUIET_CLIMB = 100 -- vario climb sound muted below 100 fpm (~1 knot, 0.5 m/s)
project_settings.QUIET_SINK = -150 -- vario sink sound muted above 150 fpm (~1.5 knot, 0.75 m/s)
project_settings.VARIO_VOLUME = 350 -- vario sound volume, set to 0 to mute
project_settings.VARIO_302_MODE = 1 -- initial operating mode for the 302 vario (0=stf, 1=auto, 2=te)

-- Panel CLOCK instrument - sim time or real time
project_settings.CLOCK_MODE = 0 -- cockpit panel clock display simulator local time (CLOCK_MODE=0)
                                -- simulator Zulu time (CLOCK_MODE = 1)
                                -- or real-world local time (CLOCK_MODE = 2)

-- TRIM trigger calibration, must match aircraft for trigger trim to set accurately
project_settings.TRIM_SPEEDS_KTS = { 45, 57, 84 } -- cruise speeds (knots) for trim range +1..0..-1
