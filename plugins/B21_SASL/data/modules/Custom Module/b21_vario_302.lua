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

         DEBUG - a couple of display areas on the gauge
         **********************************************************************
        <Element id="debug 1">
            <FloatPosition>230.000,175.000</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number)</Visibility>
            <GaugeText id="B21_mc">
                <GaugeString>Ver 1.4</GaugeString>
            </GaugeText>
        </Element>
        <Element id="debug2">
            <FloatPosition>0.000,445</FloatPosition>
            <Visibility>0</Visibility>
            <GaugeText id="B21_mc">
                <GaugeString>%((L:B21_gpsnav_wp_distance, meters) )%!7.1f!</GaugeString>
            </GaugeText>
        </Element>
]]
-- DataRefs
--  "TOTAL WEIGHT"
DATAREF_TIME_S
DATAREF_ALT_FT
DATAREF_AIRSPEED_KTS
DATAREF_AIRSPEED_MPS
DATAREF_TE_MPS
DATAREF_TE_FPM
DATAREF_TE_KTS
DATAREF_TOTAL_WEIGHT

-- Values read from polar.lua
local B21_302_polar_speed_0_mps = 0 -- CONSTANT
local B21_302_polar_sink_0_mps = 10 -- CONSTANT

-- points from polar curve { speed kps, sink m/s }
local polar = {
    { 65.0, 0.8 },
    { 70.0, 0.75 },
    { 80.0, 0.7 },
    { 90.0, 0.76 },
    { 100.0, 0.78 },
    { 120.0, 1.05 },
    { 140.0, 1.5 },
    { 160.0, 2.1 },
    { 180.0, 3.5 },
    { 200.0, 4.0 },
    { 250.0, 10.0 } -- guess, off end of published polar
}
--
local B21_polar_weight_empty_kg = 430 -- ASK21 360kg empty + 70kg for solo pilot
local B21_polar_weight_full_kg = 600 -- max weight, but no ballast anyway
--
local B21_polar_stf_best_kph = 97 -- speed to fly in zero sink (ASK21)
local B21_polar_stf_2_kph = 130    -- speed to fly in -2 m/s sink (ASK21)

-- b21_302 globals
local B21_302_maccready_kts = 4 -- user input maccready setting in kts
local B21_302_maccready_mps = 2 -- user input maccready setting in m/s

local B21_302_climb_average_mps = 0 -- calculated climb average

local B21_polar_stf_best_mps = B21_polar_stf_best_kph * 0.277778
local B21_polar_stf_2_mps = B21_polar_stf_2_kph * 0.277778

-- some constants derived from polar to use in the speed-to-fly calculation
local B21_302_polar_const_r = (B21_polar_stf_2_mps^2 - B21_polar_stf_best_mps^2) / 2
local B21_302_polar_const_v2stfx = 625 -- threshold speed-squared (m/s) figure to adjust speed-to-fly if below this (i.e. 25 m/s)
local B21_302_polar_const_z = 300000

local B21_302_prev_ballast = 1 -- previous ballast ratio, used to detect change in value & update polar_adjust
local B21_302_ballast_adjust = 1 -- adjustment factor for ballast, shifts polar by sqrt of weight ratio

-- vario modes
local B21_302_mode_stf = true  -- speed to fly
local B21_302_mode_polar = false

-- total energy
local B21_302_te_mps = 0

-- Next waypoint altitude msl (m), bearing (radians), distance (m)
local B21_302_wp_msl_m = 0.0
local B21_302_wp_bearing_radians = 0.0
local B21_302_distance_to_go_m = 0.0

-- Maccready speed-to-fly and polar sink value at that speed
local B21_302_mc_stf_mps = 0.0
local B21_302_mc_sink_mps = 0.0

-- previous update time (float seconds)
local prev_time_s = 0

-- previous altitude (float meters)
local prev_alt_m = 0

-- previous speed squared (float (m/s)^2 )
local prev_speed_mps_2 = 0

-- the datarefs we will READ to get time, altitude and speed from the sim
local DATAREF_TIME_S =  globalPropertyf("sim/network/misc/network_time_sec")
local DATAREF_ALT_FT = globalPropertyf("sim/cockpit2/gauges/indicators/altitude_ft_pilot")
-- (for calibration) local sim_alt_m = globalPropertyf("sim/flightmodel/position/elevation")
local DATAREF_AIRSPEED_KTS = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
-- (for calibration) local sim_speed_mps = globalPropertyf("sim/flightmodel/position/true_airspeed")
local DATAREF_TOTAL_WEIGHT_KG = globalPropertyf("sim/flightmodel/weight/m_total")
local DATAREF_NEXT_WAYPOINT_ALT_M --debug
local DATAREF_WP_BEARING_RADIANS --debug
local DATAREF_WP_DISTANCE_METERS --debug
local DATAREF_AMBIENT_WIND_DIRECTION_RADIANS --debug
local AMBIENT_WIND_VELOCITY_MPS --debug

-- create global DataRefs we will WRITE (name, default, isNotPublished, isShared, isReadOnly)
local DATAREF_TE_MPS = createGlobalPropertyf("b21/ask21/total_energy_mps", 0.0, false, true, true)
local DATAREF_TE_FPM = createGlobalPropertyf("b21/ask21/total_energy_fpm", 0.0, false, true, true)
local DATAREF_TE_KTS = createGlobalPropertyf("b21/ask21/total_energy_kts", 0.0, false, true, true)

-- ----------------------------------------------
-- calculates ratio of extra weight 0.0..1.0
function update_ballast()
    B21_302_ballast = (DATAREF_TOTAL_WEIGHT_KG - B21_polar_weight_empty_kgs) / (B21_polar_weight_full_kg - B21_polar_weight_empty_kg)
end


-- Calculate B21_302_ballast_adjust which is:
--  the square root of the proportion glider weight is above polar_weight_empty, i.e.
--  ballast = 0.0 (zero ballast, glider at empty weight) => polar_adjust = 1
--  ballast = 1.0 (full ballast, glider at full weight) => polar_adjust = sqrt(weight_full/weight_empty)
function update_polar()
    if B21_302_prev_ballast ~= B21_302_ballast
    then
        B21_302_ballast_adjust = math.sqrt(1 + B21_polar_weight_full_kg * B21_302_ballast / B21_polar_weight_empty_kg - B21_302_ballast)
    end
end

-- calcular polar sink in m/s for given airspeed in km/h
function sink_mps(speed_kph, ballast_adjust)
    local prev_point = { 0, 10 } -- arbitrary starting polar point (for speed < polar[1][SPEED])
    for i, point in pairs(polar)
    do
        -- adjust this polar point to account for ballast carried
        local adjusted_point = { point[1] * ballast_adjust, point[2] * ballast_adjust }
        if ( speed_kph < point[SPEED])
        then
            return interp(speed_kph, prev_point, adjusted_point )
        end
        prev_point = adjusted_point
    end
    return 10 -- we fell off the end of the polar, so guess sink value (10 m/s)
end
    
-- interpolate between points p1 and p2 on the polar
function interp(speed, p1, p2)
    set(b21_debug_polar_p1_mps, p1[SINK])
    set(b21_debug_polar_p2_mps, p2[SINK])
    local ratio = (speed - p1[SPEED]) / (p2[SPEED] - p1[SPEED])
    return p1[SINK] + ratio * (p2[SINK]-p1[SINK])
end

function update_polar_sink()
    local airspeed_kph = get(DATAREF_AIRSPEED_KTS) * 1.852
    B21_302_polar_sink_mps = sink_mps(airspeed_kph, B21_302_ballast_adjust)
end

function update_total_energy()
    
	-- calculate time (float seconds) since previous update
	local time_delta_s = get(DATAREF_TIME_S) - prev_time_s
	
	-- only update max 20 times per second (i.e. time delta > 0.05 seconds)
	if time_delta_s > 0.05
	then
		-- get current speed in m/s
		local speed_mps = get(DATAREF_AIRSPEED_KTS) * 0.514444
		-- (for calibration) local speed_mps = get(sim_speed_mps)

		-- calculate current speed squared (m/s)^2
		local speed_mps_2 = speed_mps * speed_mps
		
		-- TE speed adjustment (m/s)
		local te_adj_mps = (speed_mps_2 - prev_speed_mps_2) / (2 * 9.81 * time_delta_s)
		
		-- calculate altitude delta (meters) since last update
		local alt_delta_m = get(DATAREF_ALT_FT) * 0.3048 - prev_alt_m
		-- (for calibration) local alt_delta_m = get(sim_alt_m) - prev_alt_m
		
		-- calculate plain climb rate
		local climb_mps = alt_delta_m / time_delta_s
		
		-- calculate new vario compensated reading using 70% current and 30% new (for smoothing)
		local te_mps = get(DATAREF_TE_MPS) * 0.7 + (climb_mps + te_adj_mps) * 0.3
		
		-- limit the reading to 7 m/s max to avoid a long recovery time from the smoothing
		if te_mps > 7
		then
			te_mps = 7
		end
		
		-- all good, transfer value to the needle
        -- write value to datarefs
        set(DATAREF_TE_MPS, te_mps) -- meters per second

        set(DATAREF_TE_FPM, te_mps * 196.85) -- feet per minute

        set(DATAREF_TE_KTS, te_mps * 1.94384) -- knots
		
		-- store time, altitude and speed^2 as starting values for next iteration
		prev_time_s = get(DATAREF_TIME_S)
		prev_alt_m = get(DATAREF_ALT_FT) * 0.3048
		-- (for calibration) prev_alt_m = get(sim_alt_m)
        prev_speed_mps_2 = speed_mps_2
        -- finally write value
        B21_302_te_mps = te_mps
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
    local B21_302_stf_temp_a =  B21_polar_const_r * (B21_302_maccready_mps - B21_302_netto_mps) + B21_polar_stf_best_mps^2
    if B21_302_stf_temp_a < B21_302_polar_const_v2stfx
    then
        B21_302_stf_temp_a = 1.0 / ((B21_302_polar_const_v2stfx - B21_302_stf_temp_a) / B21_302_polar_const_z + (1.0 / B21_302_polar_const_v2stfx))
    end
    B21_302_stf_mps = math.sqrt(B21_302_stf_temp_a) * math.sqrt(B21_302_ballast_adjust)
end

--[[
                    CALCULATE DESTINATION ALT METERS MSL
                    Outputs:
                        (L:B21_302_wp_msl, meters)
                    CALCULATE B21_302_wp_bearing_radians and B21_distance_to_go_m
]]

function update_wp_alt_bearing_and_distance()
    --debug we might need to do some trig here
    B21_302_wp_msl_m = get(DATAREF_NEXT_WAYPOINT_ALT_M)
    B21_302_wp_bearing_radians = get(DATAREF_WP_BEARING_RADIANS)
    B21_302_distance_to_go_m = get(DATAREF_WP_DISTANCE_METERS)
end

--[[
                    CALCULATE STF FOR CURRENT MACCREADY (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_stf, meters per second)
]]

function update_maccready_stf()
    B21_302_mc_stf_mps = math.sqrt(B21_302_maccready_mps * B21_302_polar_const_r + B21_polar_stf_best_mps^2) * math.sqrt(B21_302_ballast_adjust)
end

--[[<Comment><Value>*******************************************************
                    CALCULATE POLAR SINK RATE AT MACCREADY STF (SINK RATE IS +ve)
                    (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_sink, meters per second)
                    Inputs:
                        (L:B21_302_mc_stf, meters per second)
                        (L:B21_302_ballast_adjust, number)
]]

function update_macready_sink()
    B21_302_mc_sink_mps = sink_mps(B21_302_mc_stf_mps, B21_302_ballast_adjust)
end

--[[                    CALCULATE ARRIVAL HEIGHT
                Outputs: 
                    (L:B21_arrival_height, meters)
                    (L:B21_height_needed, meters)
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
                        (L:B21_302_mc_sink, meters per second) * (&gt;L:B21_height_needed, meters)
                        
                        (A:PLANE ALTITUDE, meters) (L:B21_height_needed, meters) - 
                        (L:B21_302_wp_msl, meters) -
                        (&gt;L:B21_arrival_height, meters)
]]

function update_arrival_height()
    --debug still to do
end

--[[                    CALCULATE ACTUAL GLIDE RATIO
         **********************************************************************
         </Value></Comment>
        <Element id="expression_actual_glide">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99999.000</Minimum>
                    <Maximum>99999.000</Maximum>
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
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>**********************************************************************
                    CALCULATE AVERAGE CLIMB (m/s) (L:B21_302_climb_average, meters per second)
         *************************************************************************************
         </Value></Comment>
        <Element id="average_climb">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
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
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE STF NEEDLE VALUE (m/s)
         **********************************************************************
         </Value></Comment>
        <Element id="expression_sound">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99.000</Minimum>
                    <Maximum>99.000</Maximum>
                    <Script>
                            (A:AIRSPEED INDICATED, meters per second)
                            (L:B21_302_stf, meters per second) -
                            7 / 
                            (&gt;L:B21_302_stf_needle, meters per second)
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CHOOSE NEEDLE TE OR STF (m/s)
         **********************************************************************
         </Value></Comment>
        <Element id="expression_sound">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99.000</Minimum>
                    <Maximum>99.000</Maximum>
                    <Script>
                        (L:B21_302_mode_stf, number) 0 == if{
                            (L:B21_302_te, meters per second) (&gt;L:B21_302_needle, meters per second)
                        } els{
                            (L:B21_302_stf_needle, meters per second) (&gt;L:B21_302_needle, meters per second)
                        }
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE SOUND VALUES (m/s)
                    writes (L:B21_302_needle, meters per second) to b21_audio.dll
                    via the (C:B21_VARIO:VARIOMETER RATE) custom variable
         **********************************************************************
         </Value></Comment>
        <Element id="expression_sound">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Comment><Value>
                            controls b21_vario.dll
                    </Value></Comment>
                    <Minimum>-99.000</Minimum>
                    <Maximum>99.000</Maximum>
                    <Script>
                        (L:B21_302_mode_stf, number) (&gt;C:B21_VARIO:ACTIVE)
                                                
                        (L:B21_302_needle, meters per second) (&gt;C:B21_VARIO:VARIOMETER RATE)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
         **********************************************************************
                    DISPLAY ELEMENTS
         **********************************************************************
         **********************************************************************
         </Value></Comment>
        <Comment><Value>*******************************************************
                    L/D Ratio
         **********************************************************************
         </Value></Comment>
        <Element id="LD ratio">
            <FloatPosition>50,320</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number)</Visibility>
            <GaugeText id="actual glide ratio">
                <Size>278,150</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#ff0000</FontColor>
                <FontHeight>150</FontHeight>
                <Length>2</Length>
                <Transparent>True</Transparent>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <VerticalAlign>TOP</VerticalAlign>
                <GaugeString>%( (L:B21_302_glide_ratio, number) )%!2.0f!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    MacCready setting
         **********************************************************************
         </Value></Comment>
        <Element id="maccready knots">
            <FloatPosition>403,300</FloatPosition>
            <Visibility>(P:Units of measure, enum) 2 &lt; 
                        (L:B21_302_mode_polar, number) 0 == &amp;&amp;</Visibility>
            <GaugeText id="B21_mc">
                <Size>185,185</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>167</FontHeight>
                <Length>1</Length>
                <Transparent>True</Transparent>
                <VerticalAlign>CENTER</VerticalAlign>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <GaugeString>%( (L:B21_302_maccready, knots) )%!d!</GaugeString>
            </GaugeText>
        </Element>
        <Element id="maccready meters per second units">
            <FloatPosition>430,320</FloatPosition>
            <Visibility>(P:Units of measure, enum) 2 ==
                        (L:B21_302_mode_polar, number) 0 == &amp;&amp;</Visibility>
            <GaugeText id="B21_mc">
                <Size>93,150</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>150</FontHeight>
                <Length>1</Length>
                <Transparent>True</Transparent>
                <VerticalAlign>CENTER</VerticalAlign>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <GaugeString>%( (L:B21_302_maccready, knots) 2 / int)%!d!</GaugeString>
            </GaugeText>
        </Element>
        <Element id="maccready meters per second point">
            <FloatPosition>480,296</FloatPosition>
            <Visibility>(P:Units of measure, enum) 2 ==
                        (L:B21_302_mode_polar, number) 0 == &amp;&amp;</Visibility>
            <GaugeText id="B21_mc">
                <Size>93,150</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>167</FontHeight>
                <Length>1</Length>
                <Transparent>True</Transparent>
                <VerticalAlign>CENTER</VerticalAlign>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <GaugeString>.</GaugeString>
            </GaugeText>
        </Element>
        <Element id="maccready meters per second tenths">
            <FloatPosition>507,330</FloatPosition>
            <Visibility>(P:Units of measure, enum) 2 ==
                        (L:B21_302_mode_polar, number) 0 == &amp;&amp;</Visibility>
            <GaugeText id="B21_mc">
                <Size>93,185</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>120</FontHeight>
                <Length>1</Length>
                <Transparent>True</Transparent>
                <VerticalAlign>TOP</VerticalAlign>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <GaugeString>%(  (L:B21_302_maccready, knots) 2 / 10 * 10 % int  )%!d!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                     Flap position (in POLAR MODE) replaces MacCready
         **********************************************************************
         </Value></Comment>
        <Element id="flap position index">
            <FloatPosition>400,324</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number)</Visibility>
            <GaugeText id="flap handle index">
                <Size>185,185</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#ff0000</FontColor>
                <FontHeight>167</FontHeight>
                <Length>1</Length>
                <Transparent>True</Transparent>
                <VerticalAlign>CENTER</VerticalAlign>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <GaugeString>%( (A:FLAPS HANDLE INDEX, number) )%!d!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    Arrival Height
         **********************************************************************
         </Value></Comment>
        <Element id="arrival_height_gaugetext">
            <FloatPosition>0.000,215</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number) 0 ==</Visibility>
            <GaugeText id="B21_arrival_height">
                <Size>552,185</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>120</FontHeight>
                <Length>5</Length>
                <Transparent>True</Transparent>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <VerticalAlign>CENTER</VerticalAlign>
                <GaugeString>%( (P:Units of measure, enum) 2 == if{ (L:B21_arrival_height, meters) } els{ (L:B21_arrival_height, feet) } 10 / int 10 * )%!+5d!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    Airspeed km/h in POLAR MODE (replaces Arrival Height)
         **********************************************************************
         </Value></Comment>
        <Element id="arrival_height_gaugetext">
            <FloatPosition>217,225</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number)</Visibility>
            <GaugeText id="airspeed_kmh">
                <Size>350,120</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#ff0000</FontColor>
                <FontHeight>120</FontHeight>
                <Length>5</Length>
                <Transparent>True</Transparent>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <VerticalAlign>TOP</VerticalAlign>
                <GaugeString>%( (A:AIRSPEED TRUE, kilometers per hour)  )%!3.1f!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    Climb Average
         **********************************************************************
         </Value></Comment>
        <Element id="climb_avg_gaugetext">
            <FloatPosition>60,450</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number) 0 ==</Visibility>
            <GaugeText id="B21_climb_avg">
                <Size>433,185</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#404040</FontColor>
                <FontHeight>130</FontHeight>
                <Length>5</Length>
                <Transparent>True</Transparent>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <VerticalAlign>CENTER</VerticalAlign>
                <GaugeString>%( (P:Units of measure, enum) 2 == 
                                if{ 
                                    (L:B21_302_climb_average, meters per second) 
                                } els{ 
                                    (L:B21_302_climb_average, knots)
                                }
                              )%!2.1f!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    TE SINK RATE m/s (in POLAR MODE) replaces Climb Average
         **********************************************************************
         </Value></Comment>
        <Element id="sink rate_gaugetext">
            <FloatPosition>60,470</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number)</Visibility>
            <GaugeText id="te-sink">
                <Size>463,120</Size>
                <FontFace>Quartz</FontFace>
                <FontColor>#ff0000</FontColor>
                <FontHeight>120</FontHeight>
                <Length>5</Length>
                <Transparent>True</Transparent>
                <HorizontalAlign>RIGHT</HorizontalAlign>
                <VerticalAlign>TOP</VerticalAlign>
                <GaugeString>%( (L:B21_302_te, meters per second) )%!+1.2f!</GaugeString>
            </GaugeText>
        </Element>
        <Comment><Value>*******************************************************
                    PULL ARROW
         **********************************************************************
         </Value></Comment>
        <Element id="Element">
            <FloatPosition>352,156</FloatPosition>
            <Visibility>(L:B21_302_mode_stf, number) 0 ==
                        (L:B21_302_stf_needle, meters per second) 0.5 &gt; &amp;&amp;
            </Visibility>
            <Image id="pull.bmp" Name="pull_v4.bmp">
                <Transparent>True</Transparent>
            </Image>
        </Element>
        <Comment><Value>*******************************************************
                    PUSH ARROW
         **********************************************************************
         </Value></Comment>
        <Element id="Element">
            <FloatPosition>352,564</FloatPosition>
            <Visibility>(L:B21_302_mode_stf, number) 0 ==
                        (L:B21_302_stf_needle, meters per second) -0.5 &lt; &amp;&amp;
            </Visibility>
            <Image id="push.bmp" Name="push_v4.bmp">
                <Transparent>True</Transparent>
            </Image>
        </Element>
        <Comment><Value>*******************************************************
                    NEEDLE SHADOW
         **********************************************************************
         </Value></Comment>
        <Element id="Element">
            <FloatPosition>392,414</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number) 0 ==</Visibility>
            <Image id="needle_shadow_v4.bmp" Name="needle_shadow_v4.bmp">
                <Transparent>True</Transparent>
                <Axis>314,55</Axis>
            </Image>
            <Rotation id="Rotation">
                <PointsTo>WEST</PointsTo>
                <NonlinearityTable id="NonlinearityTable">
                    <NonlinearityEntry id="-5">
                        <ExpressionResult>-5</ExpressionResult>
                        <Degrees>-180</Degrees>
                    </NonlinearityEntry>
                    <NonlinearityEntry id="0">
                        <ExpressionResult>0</ExpressionResult>
                        <Degrees>0</Degrees>
                    </NonlinearityEntry>
                    <NonlinearityEntry id="5">
                        <ExpressionResult>5</ExpressionResult>
                        <Degrees>+180</Degrees>
                    </NonlinearityEntry>
                </NonlinearityTable>
                <Expression id="Expression">
                    <Minimum>-5.000</Minimum>
                    <Maximum>5.000</Maximum>
                    <Script>
                            (L:B21_302_needle, meters per second)
                    </Script>
                </Expression>
            </Rotation>
        </Element>
        <Comment><Value>*******************************************************
                    UNITS RING m/s or knots
         **********************************************************************
         </Value></Comment>
       <Element>
          <FloatPosition>57,64</FloatPosition>
          <Select id="select_units_ring">
             <Expression>
               <Minimum>0</Minimum>
               <Maximum>2</Maximum>
               <Script>(P:Units of measure, enum)</Script>
             </Expression>
             <Case id="case0">
                <ExpressionResult>0</ExpressionResult>
                <Image id="ring_k_v4.bmp" Name="ring_k_v4.bmp">
                    <Transparent>True</Transparent>
                </Image>
             </Case>
             <Case id="case1">
                <ExpressionResult>1</ExpressionResult>
                <Image id="ring_k_v4.bmp" Name="ring_k_v4.bmp">
                    <Transparent>True</Transparent>
                </Image>
             </Case>
             <Case id="case2">
                <ExpressionResult>2</ExpressionResult>
                <Image id="ring_m_v4.bmp" Name="ring_m_v4.bmp">
                    <Transparent>True</Transparent>
                </Image>
             </Case>
          </Select>
       </Element>
        <Comment><Value>*******************************************************
                    NEEDLE
         **********************************************************************
         </Value></Comment>
        <Element id="Element">
            <FloatPosition>392,387</FloatPosition>
            <Visibility>(L:B21_302_mode_polar, number) 0 ==</Visibility>
            <Image id="needle_v4.bmp" Name="needle_v4.bmp">
                <Transparent>True</Transparent>
                <Axis>314,55</Axis>
            </Image>
            <Rotation id="Rotation">
                <PointsTo>WEST</PointsTo>
                <NonlinearityTable id="NonlinearityTable">
                    <NonlinearityEntry id="-5">
                        <ExpressionResult>-5</ExpressionResult>
                        <Degrees>-180</Degrees>
                    </NonlinearityEntry>
                    <NonlinearityEntry id="0">
                        <ExpressionResult>0</ExpressionResult>
                        <Degrees>0</Degrees>
                    </NonlinearityEntry>
                    <NonlinearityEntry id="5">
                        <ExpressionResult>5</ExpressionResult>
                        <Degrees>+180</Degrees>
                    </NonlinearityEntry>
                </NonlinearityTable>
                <Expression id="Expression">
                    <Minimum>-5.000</Minimum>
                    <Maximum>5.000</Maximum>
                    <Script>
                            (L:B21_302_needle, meters per second)
                    </Script>
                </Expression>
            </Rotation>
        </Element>
        <Comment><Value>*******************************************************
                    Mc Knob
         **********************************************************************
         </Value></Comment>
        <Element id="Element">
            <FloatPosition>72,750</FloatPosition>
            <Image id="knob_v4.bmp" Name="knob_v4.bmp">
                <Transparent>True</Transparent>
                <Axis>59,59</Axis>
            </Image>
            <Rotation id="Rotation">
                <PointsTo>WEST</PointsTo>
                <Expression id="Expression">
                    <Minimum>0.000</Minimum>
                    <Maximum>7.000</Maximum>
                    <Script>(L:B21_302_maccready, meters per second) 1.2 *
                    </Script>
                </Expression>
            </Rotation>
        </Element>
        <Comment><Value>*******************************************************
         **********************************************************************
                    MOUSEAREA
         **********************************************************************
         **********************************************************************
         </Value></Comment>
        <MouseArea id="MouseArea all">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Size>785,810</Size>
            <MouseArea>
                <FloatPosition>40,305</FloatPosition>
                <Size>260,185</Size>
                <CursorType>Hand</CursorType>
                    <MouseClick id="LDvis">
                        <Script>
                        (L:B21_302_mode_polar, number) 0 == if{ 
                            1 (&gt;L:B21_302_mode_polar, number)
                        } els{
                            0 (&gt;L:B21_302_mode_polar, number)
                        }
                        </Script>
                        <ClickType>LeftSingle</ClickType>
                    </MouseClick>
    			<Tooltip id="Tooltip"> 
    				<DefaultScript>Polar measure mode</DefaultScript> 
    			</Tooltip>
            </MouseArea>
            <MouseArea id="knob">
                <FloatPosition>0,650</FloatPosition>
                <Size>160,160</Size>
                <MouseArea id="left_knob_plus">
                    <FloatPosition>0.000,0.000</FloatPosition>
                    <Size>160,80</Size>
                    <CursorType>UpArrow</CursorType>
                    <MouseClick id="MouseClick">
                        <Script>
                        (L:B21_302_maccready, knots) 7 &lt; if{ 
                        (L:B21_302_maccready, knots) 1 + int (&gt;L:B21_302_maccready, knots)
                        }
                        </Script>
                        <ClickType>LeftSingle</ClickType>
                    </MouseClick>
                    <Tooltip id="Tooltip"> 
                        <DefaultScript>MacCready Adjust</DefaultScript> 
                    </Tooltip>
                </MouseArea>
                <MouseArea id="knob_minus">
                    <FloatPosition>0,80</FloatPosition>
                    <Size>160,80</Size>
                    <CursorType>DownArrow</CursorType>
                    <MouseClick id="MouseClick">
                        <Script>
                        (L:B21_302_maccready, knots) 0 &gt; if{ 
                        (L:B21_302_maccready, knots) 1 - int (&gt;L:B21_302_maccready, knots)
                        }
                        </Script>
                        <ClickType>LeftSingle</ClickType>
                    </MouseClick>
                    <Tooltip id="Tooltip"> 
                        <DefaultScript>MacCready Adjust</DefaultScript> 
                    </Tooltip>
                </MouseArea>
            </MouseArea>
        </MouseArea>
    </SimGauge.Gauge>
</SimBase.Document>
]]

