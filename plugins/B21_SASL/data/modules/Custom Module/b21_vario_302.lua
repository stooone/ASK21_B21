-- B21

-- Computer vario simulation

--[[
        <FloatPosition>0.000,0.000</FloatPosition>
        <Size>785,810</Size>
        <Image id="302_background_v4.bmp" Name="302_background_v4.bmp">

        THIS GAUGE READS THE POLAR FROM polar.xml
                    Version 2.4
                    
                    The instrument has three basic modes for dev purposes:
                    
                    Normal: the needle is STF, with Arrival Height, MacCready, Climb Avg.
                    TE/STF: clicking the top-center position of the gauge flips needle and sound between TE and STF.
                            in TE mode, push and pull arrows appear
                    Polar mode: clicking on the face at 9 o'clock puts gauge into 'glider development' mode
                            the gauge displays:
                                Airspeed in km/h (in place of the Arrival Height)
                                L/D ratio (at 9 o'clock)
                                Flap index (at 3 o'clock replacing MacCready)
                                Sink rate (TE compensated for convenience) in m/s (replacing climb avg)

    user inputs:
        B21_302_mode_stf   -- (true/false) toggles vario between STF and TE mode
        B21_302_mode_polar -- (true/false) displays debug info
        B21_302_maccready_kts -- MacCready setting dialled in by pilot

    display values
        B21_302_needle_fpm
        B21_302_glide_ratio -- debug info
        B21_302_arrival_height_m
        B21_302_climb_average_mps

]]
-- the datarefs we will READ to get time, altitude and speed from the sim
DATAREF = {}
DATAREF.MACCREADY = 2.0                      -- debug write this from instrument MacCready knob
DATAREF.TIME_S = 100.0                       -- globalPropertyf("sim/network/misc/network_time_sec")
DATAREF.ALT_FT = 3000.0                      -- globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
-- (for calibration) local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
DATAREF.AIRSPEED_KTS = 60.0                  -- globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
-- (for calibration) local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")
DATAREF.WEIGHT_TOTAL_KG = 430.0              -- globalPropertyf("sim/flightmodel/weight/m_total")
DATAREF.NEXT_WAYPOINT_ALT_M = 100.0          -- debug
DATAREF.WP_BEARING_RADIANS = 0.0             -- debug
DATAREF.WP_DISTANCE_M = 2000.0               -- debug
DATAREF.WIND_RADIANS = 0.0 -- debug
DATAREF.WIND_MPS = 0.0      -- debug

-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
DATAREF.TE_MPS = 0.0     -- createGlobalPropertyf("b21/ask21/total_energy_mps", 0.0, false, true, true)
DATAREF.TE_FPM = 0.0     -- createGlobalPropertyf("b21/ask21/total_energy_fpm", 0.0, false, true, true)
DATAREF.TE_KTS = 0.0     -- createGlobalPropertyf("b21/ask21/total_energy_kts", 0.0, false, true, true)
DATAREF.PULL = 0         -- createGlobalPropertyi("b21/ask21/302_pull", 0, false, true, true)
DATAREF.PUSH = 0         -- createGlobalPropertyi("b21/ask21/302_push", 0, false, true, true)
DATAREF.NEEDLE_FPM = 0.0 -- createGlobalPropertyf("b21/ask21/302_needle_fpm", 0.0, false, true, true)
DATAREF.B21_VARIO_SOUND_FPM = 0.0 --debug

function dataref_read(x)
    return DATAREF[x]
end

function dataref_write(x, value)
    DATAREF[x] = value
end

-- Conversion constants
FT_TO_M = 0.3048
KTS_TO_KPH = 1.852
KTS_TO_MPS = 0.514444
MPS_TO_FPM = 196.85
MPS_TO_KTS = 1.0 / KTS_TO_MPS
MPS_TO_KPH = 3.6
KPH_TO_MPS = 1 / MPS_TO_KPH

-- #########################################################################################
-- ##                  POLAR SETTINGS UPDATED FOR EACH GLIDER                        #######
-- #########################################################################################
-- #                                                                                       #
-- points from polar curve { speed kps, sink m/s }                                      -- #
polar = {                                                                               -- #
    { 65.0, 0.8 },                                                                      -- #
    { 70.0, 0.75 },                                                                     -- #
    { 80.0, 0.7 },                                                                      -- #
    { 90.0, 0.76 },                                                                     -- #
    { 100.0, 0.78 },                                                                    -- #
    { 120.0, 1.05 },                                                                    -- #
    { 140.0, 1.5 },                                                                     -- #
    { 160.0, 2.1 },                                                                     -- #
    { 180.0, 3.5 },                                                                     -- #
    { 200.0, 4.0 },                                                                     -- #
    { 250.0, 10.0 } -- backstop, off end of published polar                             -- #
}                                                                                       -- #
--                                                                                      -- #
B21_polar_weight_empty_kg = 430 -- ASK21 360kg empty + 70kg for solo pilot              -- #
B21_polar_weight_full_kg = 600 -- max weight, but no ballast anyway                     -- #
--                                                                                      -- #
B21_polar_stf_best_kph = 97 -- speed to fly in zero sink (ASK21)                        -- #
B21_polar_stf_2_kph = 130    -- speed to fly in -2 m/s sink (ASK21)                     -- #
                                                                                        -- #
-- #                                                                                    -- #
-- #########################################################################################
-- ### END OF POLAR SETTINGS                                                         #######
-- #########################################################################################

-- b21_302 globals
B21_302_maccready_kts = 4 -- user input maccready setting in kts
B21_302_maccready_mps = 2 -- user input maccready setting in m/s

B21_302_climb_average_mps = 0 -- calculated climb average

B21_polar_stf_best_mps = B21_polar_stf_best_kph * KPH_TO_MPS
B21_polar_stf_2_mps = B21_polar_stf_2_kph * KPH_TO_MPS

-- some constants derived from polar to use in the speed-to-fly calculation
B21_302_polar_const_r = (B21_polar_stf_2_mps^2 - B21_polar_stf_best_mps^2) / 2
B21_302_polar_const_v2stfx = 625 -- threshold speed-squared (m/s) figure to adjust speed-to-fly if below this (i.e. 25 m/s)
B21_302_polar_const_z = 300000

B21_302_ballast_ratio = 0.0 -- proportion of ballast carried 0..1
B21_302_ballast_adjust = 1.0 -- adjustment factor for ballast, shifts polar by sqrt of total_weight / weight_empty

-- vario modes
B21_302_mode_stf = true  -- speed to fly
B21_302_mode_polar = false

-- total energy
B21_302_te_mps = 0.0

-- netto
B21_302_polar_sink_mps = 0.0
B21_302_netto_mps = 0.0

-- Next waypoint altitude msl (m), bearing (radians), distance (m)
B21_302_wp_msl_m = 0.0
B21_302_wp_bearing_radians = 0.0
B21_302_distance_to_go_m = 0.0

-- Maccready speed-to-fly and polar sink value at that speed
B21_302_mc_stf_mps = 0.0
B21_302_mc_sink_mps = 0.0

-- height needed and arrivial height at next waypoint
B21_302_height_needed_m = 0.0
B21_302_arrival_height_m = 0.0

-- debug glide ratio
B21_302_glide_ratio = 0.0

-- vario needle value
B21_302_needle_fpm = 0.0


-- #############################################################
-- vars used by routines to track changes between update() calls

prev_ballast = 0.0

-- previous update time (float seconds)
prev_time_s = 99.0 --debug

-- previous altitude (float meters)
prev_alt_m = 913.0 --debug

-- previous speed squared (float (m/s)^2 )
prev_speed_mps_2 = 952.75 --debug 60knots

-- time period start used by average
average_start_s = 97.0 --debug

-- #################################################################################################

-- Calculate B21_302_ballast_adjust which is:
--  the square root of the proportion glider weight is above polar_weight_empty, i.e.
--  ballast = 0.0 (zero ballast, glider at empty weight) => polar_adjust = 1
--  ballast = 1.0 (full ballast, glider at full weight) => polar_adjust = sqrt(weight_full/weight_empty)
function update_ballast()
    B21_302_ballast_ratio = (dataref_read("WEIGHT_TOTAL_KG") - B21_polar_weight_empty_kg) / 
                            (B21_polar_weight_full_kg - B21_polar_weight_empty_kg)
    
    B21_302_ballast_adjust = math.sqrt(dataref_read("WEIGHT_TOTAL_KG")/ B21_polar_weight_empty_kg)
    print("B21_302_ballast_ratio",B21_302_ballast_ratio) --debug
    print("B21_302_ballast_adjust",B21_302_ballast_adjust) --debug
end

function update_maccready()
    --debug read knob on cockpit panel
    B21_302_maccready_mps = dataref_read("MACCREADY")
    B21_302_maccready_kts = B21_302_maccready_mps * MPS_TO_KTS
    print("B21_302_maccready_kts", B21_302_maccready_kts) --debug
end

-- calcular polar sink in m/s for given airspeed in km/h
function sink_mps(speed_kph, ballast_adjust)
    local prev_point = { 0, 10 } -- arbitrary starting polar point (for speed < polar[1][SPEED])
    for i, point in pairs(polar) -- each point is { speed_kph, sink_mps }
    do
        -- adjust this polar point to account for ballast carried
        local adjusted_point = { point[1] * ballast_adjust, point[2] * ballast_adjust }
        if ( speed_kph < adjusted_point[1])
        then
            return interp(speed_kph, prev_point, adjusted_point )
        end
        prev_point = adjusted_point
    end
    return 10 -- we fell off the end of the polar, so guess sink value (10 m/s)
end
    
-- interpolate sink for speed between between points p1 and p2 on the polar
-- p1 and p2 are { speed_kph, sink_mps } where sink is positive
function interp(speed, p1, p2)
    local ratio = (speed - p1[1]) / (p2[1] - p1[1])
    return p1[2] + ratio * (p2[2]-p1[2])
end

function update_polar_sink()
    local airspeed_kph = dataref_read("AIRSPEED_KTS") * KTS_TO_KPH
    B21_302_polar_sink_mps = sink_mps(airspeed_kph, B21_302_ballast_adjust)
    print("B21_302_polar_sink_mps",B21_302_polar_sink_mps) --debug
end

-- calculate TE value from time, altitude and airspeed
function update_total_energy()
    
	-- calculate time (float seconds) since previous update
	local time_delta_s = dataref_read("TIME_S") - prev_time_s
	print("time_delta_s ",time_delta_s) --debug
	-- only update max 20 times per second (i.e. time delta > 0.05 seconds)
	if time_delta_s > 0.05
	then
		-- get current speed in m/s
		local speed_mps = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS
		-- (for calibration) local speed_mps = dataref_read(sim_speed_mps)

		-- calculate current speed squared (m/s)^2
		local speed_mps_2 = speed_mps * speed_mps
		print("speed_mps^2 now",speed_mps_2)
		-- TE speed adjustment (m/s)
		local te_adj_mps = (speed_mps_2 - prev_speed_mps_2) / (2 * 9.81 * time_delta_s)
		print("te_adj_mps", te_adj_mps) --debug
		-- calculate altitude delta (meters) since last update
		local alt_delta_m = dataref_read("ALT_FT") * 0.3048 - prev_alt_m
		-- (for calibration) local alt_delta_m = dataref_read(sim_alt_m) - prev_alt_m
		print("alt_delta_m",alt_delta_m) --debug
		-- calculate plain climb rate
		local climb_mps = alt_delta_m / time_delta_s
		print("rate of climb m/s", climb_mps) -- debug
		-- calculate new vario compensated reading using 70% current and 30% new (for smoothing)
		local te_mps = B21_302_te_mps * 0.7 + (climb_mps + te_adj_mps) * 0.3
		
		-- limit the reading to 7 m/s max to avoid a long recovery time from the smoothing
		if te_mps > 7
		then
			te_mps = 7
		end
		
		-- all good, transfer value to the needle
        -- write value to datarefs
        dataref_write("TE_MPS", te_mps) -- meters per second

        dataref_write("TE_FPM", te_mps * MPS_TO_FPM) -- feet per minute

        dataref_write("TE_KTS", te_mps * MPS_TO_KTS) -- knots
		
		-- store time, altitude and speed^2 as starting values for next iteration
		prev_time_s = dataref_read("TIME_S")
		prev_alt_m = dataref_read("ALT_FT") * FT_TO_M
		-- (for calibration) prev_alt_m = dataref_read(sim_alt_m)
        prev_speed_mps_2 = speed_mps_2
        -- finally write value
        B21_302_te_mps = te_mps
        print("B21_302_te_mps", B21_302_te_mps)
	end
    
		
end -- update_total_energy

--[[ *******************************************************
CALCULATE NETTO (sink is negative)
Inputs:
    B21_302_te_mps
    B21_302_polar_sink_mps
Outputs:
    L:B21_302_netto_mps

Simply add the calculated polar sink (+ve) back onto the TE reading
E.g. TE says airplane sinking at 2.5 m/s (te = -2.5)
 Polar says aircraft should be sinking at 1 m/s (polar_sink = +1)
 Netto = te + netto = (-2.5) + 1 = -1.5 m/s
]]

function update_netto()
    B21_302_netto_mps = B21_302_te_mps + B21_302_polar_sink_mps
    print("B21_302_netto_mps",B21_302_netto_mps) --debug
end

--[[
                    CALCULATE STF
                    Outputs:
                        (L:B21_302_stf, meters per second)
                    Inputs:
                        (L:B21_302_polar_const_r, number)
                        (L:B21_302_polar_const_v2stfx, number) = if temp_a is less than this, then tweak stf (high lift)
                        (L:B21_302_polar_const_z, number)
                        (L:B21_302_netto, meters per second)
                        (L:B21_302_maccready, meters per second)
                        (L:B21_302_ballast_adjust, number)
                         
                     Vstf = sqrt(R*(maccready-netto) + sqr(stf_best))*sqrt(polar_adjust)
                     
                     if in high lift area then this formula has error calculating negative speeds, so adjust:
                     if R*(maccready-netto)+sqr(Vbest) is below a threshold (v2stfx) instead use:
                        1 / ((v2stfx - [above calculation])/z + 1/v2stfx)
                     this formula decreases to zero at -infinity instead of going negative
]]

-- writes B21_302_stf_mps (speed to fly in m/s)
function update_stf()
    -- stf_temp_a is the initial speed-squared value representing the speed to fly
    -- it will be adjusted if it's below (25 m/s)^2 i.e. vario is proposing a very slow stf (=> strong lift)
    -- finally it will be adjusted according to the ballast ratio
    local B21_302_stf_temp_a =  B21_302_polar_const_r * (B21_302_maccready_mps - B21_302_netto_mps) + B21_polar_stf_best_mps^2
    if B21_302_stf_temp_a < B21_302_polar_const_v2stfx
    then
        B21_302_stf_temp_a = 1.0 / ((B21_302_polar_const_v2stfx - B21_302_stf_temp_a) / B21_302_polar_const_z + (1.0 / B21_302_polar_const_v2stfx))
    end
    B21_302_stf_mps = math.sqrt(B21_302_stf_temp_a) * math.sqrt(B21_302_ballast_adjust)
    print("B21_302_stf_mps",B21_302_stf_mps, "(",B21_302_stf_mps * MPS_TO_KPH,"kph)") -- debug
end

--[[
                    CALCULATE DESTINATION ALT METERS MSL
                    Outputs:
                        B21_302_wp_msl_m
                        B21_302_wp_bearing_radians
                        B21_302_distance_to_go_m
]]

function update_wp_alt_bearing_and_distance()
    --debug we might need to do some trig here
    B21_302_wp_msl_m = dataref_read("NEXT_WAYPOINT_ALT_M")
    B21_302_wp_bearing_radians = dataref_read("WP_BEARING_RADIANS")
    B21_302_distance_to_go_m = dataref_read("WP_DISTANCE_M")
    print("B21_302_wp_msl_m",B21_302_wp_msl_m) --debug
    print("B21_302_wp_bearing_radians",B21_302_wp_bearing_radians) --debug
    print("B21_302_distance_to_go_m", B21_302_distance_to_go_m) --debug
end

--[[
                    CALCULATE STF FOR CURRENT MACCREADY (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_stf, meters per second)
]]

-- calculate speed-to-fly in still air for current maccready setting
function update_maccready_stf()
    B21_302_mc_stf_mps = math.sqrt(B21_302_maccready_mps * B21_302_polar_const_r + B21_polar_stf_best_mps^2) * 
                         math.sqrt(B21_302_ballast_adjust)
    print("B21_302_mc_stf_mps", B21_302_mc_stf_mps,"(", B21_302_mc_stf_mps * MPS_TO_KPH, "kph)") --debug
end

--[[
                    CALCULATE POLAR SINK RATE AT MACCREADY STF (SINK RATE IS +ve)
                    (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_sink, meters per second)
                    Inputs:
                        (L:B21_302_mc_stf, meters per second)
                        (L:B21_302_ballast_adjust, number)
]]

function update_maccready_sink()
    B21_302_mc_sink_mps = sink_mps(B21_302_mc_stf_mps * MPS_TO_KPH, B21_302_ballast_adjust)
    print("B21_302_mc_sink_mps", B21_302_mc_sink_mps,"(", B21_302_mc_stf_mps / B21_302_mc_sink_mps,"mc L/D)") --debug
end

--[[                    CALCULATE ARRIVAL HEIGHT
                Outputs: 
                    (L:B21_302_arrival_height, meters)
                    (L:B21_302_height_needed, meters)
                Inputs:
                    (A:AMBIENT WIND DIRECTION, radians)
                    (A:AMBIENT WIND VELOCITY, meters per second)
                    (A:PLANE ALTITUDE, meters)
                    (L:B21_302_mc_stf, meters per second)
                    (L:B21_302_mc_sink, meters per second)
                    (L:B21_302_wp_bearing, radians)
                    (L:B21_302_distance_to_go, meters)
                    (L:B21_302_wp_msl, meters)
                    <Script>
                        (A:AMBIENT WIND DIRECTION, radians) (L:B21_302_wp_bearing, radians) - pi - (&gt;L:B21_theta, radians)
                        (A:AMBIENT WIND VELOCITY, meters per second) (&gt;L:B21_wind_velocity, meters per second)
                        (L:B21_theta, radians) cos (L:B21_wind_velocity, meters per second) * (&gt;L:B21_x, meters per second)
                        (L:B21_theta, radians) sin (L:B21_wind_velocity, meters per second) * (&gt;L:B21_y, meters per second)
                        (L:B21_302_mc_stf, meters per second) sqr (L:B21_y, meters per second) sqr - sqrt
                        (L:B21_x, meters per second) + (&gt;L:B21_vw, meters per second)
                        (L:B21_302_distance_to_go, meters) (L:B21_vw, meters per second) /
                        (L:B21_302_mc_sink, meters per second) * (&gt;L:B21_302_height_needed, meters)
                        
                        (A:PLANE ALTITUDE, meters) (L:B21_302_height_needed, meters) - 
                        (L:B21_302_wp_msl, meters) -
                        (&gt;L:B21_302_arrival_height, meters)
]]

function update_arrival_height()
    local B21_theta_radians = dataref_read("WIND_RADIANS") - B21_302_wp_bearing_radians - math.pi

    local B21_wind_velocity_mps = dataref_read("WIND_MPS")

    local B21_x_mps = math.cos(B21_theta_radians) * B21_wind_velocity_mps

    local B21_y_mps = math.sin(B21_theta_radians) * B21_wind_velocity_mps

    local B21_vw_mps = math.sqrt(B21_302_mc_stf_mps^2 - B21_y_mps^2) + B21_x_mps

    B21_302_height_needed_m = B21_302_distance_to_go_m / B21_vw_mps * B21_302_mc_sink_mps

    B21_302_arrival_height_m = dataref_read("ALT_FT") * FT_TO_M - B21_302_height_needed_m - B21_302_wp_msl_m
    print("Wind",dataref_read("WIND_RADIANS"),"radians",dataref_read("WIND_MPS"),"mps") --debug
    print("B21_302_height_needed_m", B21_302_height_needed_m) --debug
    print("B21_302_arrival_height_m", B21_302_arrival_height_m) --debug
end

--[[                    CALCULATE ACTUAL GLIDE RATIO
                    <Script>
                        (A:AIRSPEED TRUE, meters per second) (L:B21_302_te, meters per second) neg / d
                        99 &gt;
                        if{
                            99
                        }
                        d
                        0 &lt;
                        if{
                            0
                        }
                        (&gt;L:B21_302_glide_ratio, number)

]]
function update_glide_ratio()
    local sink = -B21_302_te_mps -- sink is +ve
    if sink < 0.1 -- sink rate obviously below best glide so cap to avoid meaningless high L/D or divide by zero
    then
        B21_302_glide_ratio = 99
    else
        B21_302_glide_ratio = dataref_read("AIRSPEED_KTS") * KTS_TO_MPS / sink
    end
    print("B21_302_glide_ratio",B21_302_glide_ratio) --debug
end

--[[                CALCULATE AVERAGE CLIMB (m/s) (L:B21_302_climb_average, meters per second)
                    <Minimum>-20.000</Minimum>
                    <Maximum>20.000</Maximum>
                    <Script>
                        (E:ABSOLUTE TIME, seconds) 2 - (L:B21_302_average_start, seconds) &gt;
                        if{
                            (E:ABSOLUTE TIME, seconds) (&gt;L:B21_302_average_start, seconds)

                            (L:B21_302_climb_average, meters per second) 0.85 *
                            (L:B21_302_te, meters per second) 0.15 *
                            +
                            (&gt;L:B21_302_climb_average, meters per second)
                        }
                        (L:B21_302_climb_average, meters per second) (L:B21_302_te, meters per second) - abs 3 &gt;
                        if{
                            (L:B21_302_te, meters per second) (&gt;L:B21_302_climb_average, meters per second)
                        }

]]

-- calculate B21_302_climb_average_mps
function update_average_climb()
    -- only update 2+ seconds after last update
    if dataref_read("TIME_S") - 2 > average_start_s
    then
        average_start_s = dataref_read("TIME_S")

        -- update climb average with smoothing
        B21_302_climb_average_mps = B21_302_climb_average_mps * 0.85 + B21_302_te_mps * 0.15

        -- if the gap between average and TE > 3m/s then reset to average = TE
        if math.abs(B21_302_climb_average_mps - B21_302_te_mps) > 3.0
        then
            B21_302_climb_average_mps = B21_302_te_mps
        end
    end
    print("B21_302_climb_average_mps",B21_302_climb_average_mps) --debug
end

--[[                    CALCULATE STF NEEDLE VALUE (m/s)
                    STF:
                            (A:AIRSPEED INDICATED, meters per second)
                            (L:B21_302_stf, meters per second) -
                            7 / 
                            (&gt;L:B21_302_stf_needle, meters per second)
                    NEEDLE:
                        (L:B21_302_mode_stf, number) 0 == if{
                            (L:B21_302_te, meters per second) (&gt;L:B21_302_needle, meters per second)
                        } els{
                            (L:B21_302_stf_needle, meters per second) (&gt;L:B21_302_needle, meters per second)
                        }
]]

-- write value to B21_302_needle_fpm
function update_needle()
    local needle_mps
    if B21_302_mode_stf
    then
        needle_mps = (dataref_read("AIRSPEED_KTS") * KTS_TO_MPS - B21_302_stf_mps)/ 7
    else
        needle_mps = B21_302_te_mps
    end
    B21_302_needle_fpm = needle_mps * MPS_TO_FPM
    dataref_write("NEEDLE_FPM", B21_302_needle_fpm)
    print("B21_302_needle_fpm",B21_302_needle_fpm)--debug
end

-- write value to b21/ask21/vario_sound_fpm dataref
function update_vario_sound()
    dataref_write("B21_VARIO_SOUND_FPM", B21_302_needle_fpm)
end

-- show the 'PULL' indicator on the vario display
function update_pull()
    if B21_302_mode_stf and B21_302_needle_fpm > 100.0
    then
        dataref_write("PULL", 1)
    else
        dataref_write("PULL", 0)
    end
end

function update_push()
    if B21_302_mode_stf and B21_302_needle_fpm < -100
    then
        dataref_write("PUSH", 1)
    else
        dataref_write("PUSH", 0)
    end
end

-- Finally, here's the per-frame update() callabck
function update()
    update_ballast()
    update_maccready()
    update_polar_sink()
    update_total_energy()
    update_netto()
    update_stf()
    update_wp_alt_bearing_and_distance()
    update_maccready_stf()
    update_maccready_sink()
    update_arrival_height()
    update_glide_ratio()
    update_average_climb()
    update_needle()
    update_vario_sound()
    update_pull()
    update_push()
end
