--[[
        <FloatPosition>0.000,0.000</FloatPosition>
        <Size>785,810</Size>
        <Image id="302_background_v4.bmp" Name="302_background_v4.bmp">
            <Transparent>True</Transparent>
        </Image>
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

-- values read from polar.lua
--  B21_polar_stf_2_mps
--  B21_polar_stf_best_mps
--  B21_polar_weight_empty_kg (LS8-18 = 361Kg)
--  B21_polar_weight_full_kg (LS8-18 = 509Kg)

local B21_302_maccready_kts = 3
local B21_302_climb_average_mps = 0

local B21_302_polar_const_r = (B21_polar_stf_2_mps^2 - B21_polar_stf_best_mps^2) / 2
local B21_302_polar_const_v2stfx = 625
local B21_302_polar_const_z = 300000

local B21_302_mode_stf = true
local B21_302_mode_polar = false
local B21_302_prev_ballast = -1

--[[
                    CALCULATE BALLAST VALUES
                    (L:B21_302_ballast, number) (0..1 = proportion of ballast carried)
                    
                    inputs:
                        (L:B21_polar_weight_empty, kilograms) (LS8-18 = 361Kg)
                        (L:B21_polar_weight_full, kilograms) (LS8-18 = 509Kg)
        <Element>
            <Select id="Select">
                <Expression id="expression te">
                    <Minimum>-5.000</Minimum>
                    <Maximum>5.000</Maximum>
                    <Script>
                        (A:TOTAL WEIGHT, kilograms) (L:B21_polar_weight_empty, kilograms) - 
                        (L:B21_polar_weight_full, kilograms) (L:B21_polar_weight_empty, kilograms) - / 
                        (&gt;L:B21_302_ballast, number)
]]

function calculate_ballast()
    B21_302_ballast = (get(DATAREF TOTAL WEIGHT) - B21_polar_weight_empty_kgs) / (B21_polar_weight_full_kg - B21_polar_weight_empty_kg)
end

--[[        <Comment><Value>*******************************************************
                    CALCULATE POLAR FOR CURRENT BALLAST
                        (L:B21_302_polar_adjust, number) = adjustment factor for ballast
                        (L:B21_302_polar_speed_0 .. 6, meters per second)
                        (L:B21_302_polar_sink_0 .. 6, meters per second)
                        (L:B21_302_prev_ballast, number) = remember previous ballast (0..1) value to detect change
                        
                    Inputs:
                        (L:B21_302_ballast, number) = proportion of ballast carried (0 to 1)
                        (L:B21_polar_speed_1, meters per second) .. speed_6 from polar.xml
                        (L:B21_polar_sink_1, meters per second) .. sink_6 from polar.xml
                        (L:B21_polar_weight_full, kilograms) from polar.xml
                        (L:B21_polar_weight_empty, kilograms) from polar.xml

                        recomputes polar if ballast has changed
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="polar">
                <Expression id="Expression2">
                    <Minimum>-10.000</Minimum>
                    <Maximum>10.000</Maximum>
                    <Script>
                        (L:B21_302_prev_ballast, number) (L:B21_302_ballast, number) != if{
                            (L:B21_polar_weight_full, kilograms)
                            (L:B21_302_ballast, number) *
                            (L:B21_polar_weight_empty, kilograms) /
                            (L:B21_302_ballast, number) -
                            1 +
                            sqrt
                            (&gt;L:B21_302_polar_adjust, number)
                            
                            0  (&gt;L:B21_302_polar_speed_0, meters per second)
                            10 (&gt;L:B21_302_polar_sink_0, meters per second)
                              
                            (L:B21_polar_speed_1, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_1, meters per second)
                            (L:B21_polar_sink_1, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_1, meters per second)
                            
                            (L:B21_polar_speed_2, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_2, meters per second)
                            (L:B21_polar_sink_2, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_2, meters per second)
                            
                            (L:B21_polar_speed_3, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_3, meters per second)
                            (L:B21_polar_sink_3, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_3, meters per second)
                            
                            (L:B21_polar_speed_4, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_4, meters per second)
                            (L:B21_polar_sink_4, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_4, meters per second)
                            
                            (L:B21_polar_speed_5, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_5, meters per second)
                            (L:B21_polar_sink_5, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_5, meters per second)
                            
                            (L:B21_polar_speed_6, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_speed_6, meters per second)
                            (L:B21_polar_sink_6, meters per second) (L:B21_302_polar_adjust, number) *
                            (&gt;L:B21_302_polar_sink_6, meters per second)
                            
                            (L:B21_302_ballast, number) (&gt;L:B21_302_prev_ballast, number)
                        }
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE POLAR SINK RATE AT CURRENT AIRSPEED (SINK RATE IS +ve)
                    Outputs:
                        (L:B21_302_polar_sink, meters per second)
                    Inputs:
                        (L:B21_302_polar_speed_0..6
                        (L:B21_302_polar_sink_0..6
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="expression polar sink">
                <Expression id="Expression2">
                    <Minimum>-10.000</Minimum>
                    <Maximum>10.000</Maximum>
                    <Script>
                       (A:AIRSPEED TRUE, meters per second) (&gt;L:B21_302_temp_airspeed, meters per second)
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_1, meters per second) &lt; if{
                            (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_0, meters per second) - 
                            (L:B21_302_polar_speed_1, meters per second) (L:B21_302_polar_speed_0, meters per second) - / 
                            (L:B21_302_polar_sink_1, meters per second) (L:B21_302_polar_sink_0, meters per second) - * 
                            (L:B21_302_polar_sink_0, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_2, meters per second) &lt; if{
                            (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_1, meters per second) - 
                            (L:B21_302_polar_speed_2, meters per second) (L:B21_302_polar_speed_1, meters per second) - / 
                            (L:B21_302_polar_sink_2, meters per second) (L:B21_302_polar_sink_1, meters per second) - * 
                            (L:B21_302_polar_sink_1, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_3, meters per second) &lt; if{
                            (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_2, meters per second) - 
                            (L:B21_302_polar_speed_3, meters per second) (L:B21_302_polar_speed_2, meters per second) - / 
                            (L:B21_302_polar_sink_3, meters per second) (L:B21_302_polar_sink_2, meters per second) - * 
                            (L:B21_302_polar_sink_2, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_4, meters per second) &lt; if{
                            (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_3, meters per second) - 
                            (L:B21_302_polar_speed_4, meters per second) (L:B21_302_polar_speed_3, meters per second) - / 
                            (L:B21_302_polar_sink_4, meters per second) (L:B21_302_polar_sink_3, meters per second) - * 
                            (L:B21_302_polar_sink_3, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_5, meters per second) &lt; if{
                            (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_4, meters per second) - 
                            (L:B21_302_polar_speed_5, meters per second) (L:B21_302_polar_speed_4, meters per second) - / 
                            (L:B21_302_polar_sink_5, meters per second) (L:B21_302_polar_sink_4, meters per second) - * 
                            (L:B21_302_polar_sink_4, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_temp_airspeed, meters per second) (L:B21_302_polar_speed_5, meters per second) - 
                       (L:B21_302_polar_speed_6, meters per second) (L:B21_302_polar_speed_5, meters per second) - / 
                       (L:B21_302_polar_sink_6, meters per second) (L:B21_302_polar_sink_5, meters per second) - * 
                       (L:B21_302_polar_sink_5, meters per second) + (&gt;L:B21_302_polar_sink, meters per second)
                       :1
                       (A:AIRSPEED TRUE, meters per second) 10 &lt;
                       if{
                            (A:AIRSPEED TRUE, meters per second) 10 / d *
                            (L:B21_302_polar_sink, meters per second) *
                            (&gt;L:B21_302_polar_sink, meters per second)
                       }
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE TE (sink is negative)
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="Select">
                <Expression id="expression te">
                    <Minimum>-5.000</Minimum>
                    <Maximum>5.000</Maximum>
                    <Script>
        				(A:AIRSPEED TRUE, meters per second) d * 
        			 	19.62 /  			
        				(A:PLANE ALTITUDE, meters) + 
        				0.25 * (G:Var2) 0.75 * +	
        				d (G:Var2) -			
        				(E:ABSOLUTE TIME, seconds)
        				0.25 * (G:Var1) 0.75 * +			
        				d (G:Var1) -			
        				r (&gt;G:Var1)	
        				/			
        				r (&gt;G:Var2)				
        				0.05 * (L:B21_302_te, meters per second) 0.95 * + 
        				(&gt;L:B21_302_te, meters per second)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE NETTO (sink is negative)
                Inputs:
                        (L:B21_302_te, meters per second)
        				(L:B21_302_polar_sink, meters per second)
                Outputs:
                        (L:B21_302_netto, meters per second)

                Simply add the calculated polar sink (+ve) back onto the TE reading
                E.g. TE says airplane sinking at 2.5 m/s (te = -2.5)
                     Polar says aircraft should be sinking at 1 m/s (polar_sink = +1)
                     Netto = te + netto = (-2.5) + 1 = -1.5 m/s
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="Select">
                <Expression id="expression te">
                    <Minimum>-5.000</Minimum>
                    <Maximum>5.000</Maximum>
                    <Script>
                        (L:B21_302_te, meters per second)
        				(L:B21_302_polar_sink, meters per second) + 
                            (&gt;L:B21_302_netto, meters per second)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE STF
                    Outputs:
                        (L:B21_302_stf, meters per second)
                    Inputs:
                        (L:B21_302_polar_const_r, number)
                        (L:B21_302_polar_const_v2stfx, number) = if temp_a is less than this, then tweak stf (high lift)
                        (L:B21_302_polar_const_z, number)
                        (L:B21_302_netto, meters per second)
                        (L:B21_302_maccready, meters per second)
                        (L:B21_302_polar_adjust, number)
                         
                     Vstf = sqrt(R*(maccready-netto) + sqr(stf_best))*sqrt(polar_adjust)
                     
                     if in high lift area then this formula has error calculating negative speeds, so adjust:
                     if R*(maccready-netto)+sqr(Vbest) is below a threshold (v2stfx) instead use:
                        1 / ((v2stfx - [above calculation])/z + 1/v2stfx)
                     this formula decreases to zero at -infinity instead of going negative
                     
                     For ballast, adjust speed by sqrt(polar_adjust) = sqrt(sqrt(weight/weight_empty))
                     
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="Select">
                <Expression id="expression stf">
                    <Minimum>0.000</Minimum>
                    <Maximum>100.000</Maximum>
                    <Script>
                        (L:B21_302_maccready, meters per second)
        				(L:B21_302_netto, meters per second) -
                        (L:B21_302_polar_const_r, number) *
                        (L:B21_polar_stf_best, meters per second) sqr + d
                        (&gt;L:B21_302_stf_temp_a, number)
                        (L:B21_302_polar_const_v2stfx, number) &lt; if{
                            1
                            (L:B21_302_polar_const_v2stfx, number)
                            (L:B21_302_stf_temp_a, number) -
                            (L:B21_302_polar_const_z, number) /
                            1 (L:B21_302_polar_const_v2stfx, number) / + /
                            (&gt;L:B21_302_stf_temp_a, number)
                        }
                        (L:B21_302_stf_temp_a, number) sqrt
                        (L:B21_302_polar_adjust, number) sqrt *
                        (&gt;L:B21_302_stf, meters per second)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE DESTINATION ALT METERS MSL
                    Outputs:
                        (L:B21_302_wp_msl, meters)
                    Inputs:
                        FSX altitude of mission POI or flightplan next waypoint
         **********************************************************************
         </Value></Comment>
        <Element id="expression_actual_glide">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99999.000</Minimum>
                    <Maximum>99999.000</Maximum>
                    <Script>
                        (C:POI:SelectedTargetMSLAltitude, meters) d 0 !=
                        if{
                            (&gt;L:B21_302_wp_msl, meters)
                            quit
                        }
                        (L:B21_gpsnav_init, bool) 0 ==
                        if{
                            (A:GPS WP NEXT ALT, meters) (&gt;L:B21_302_wp_msl, meters)
                            quit
                        }                        
                        (L:B21_gpsnav_wp_alt, meters) (&gt;L:B21_302_wp_msl, meters)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE B21_302_wp_bearing and B21_distance_to_go
         **********************************************************************
         </Value></Comment>
        <Element id="bearing and distance">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99999.000</Minimum>
                    <Maximum>+99999.000</Maximum>
                    <Script>
                        (C:POI:SelectedTargetDistance, meters) 0.001 &gt; 
                        if{
                            (C:POI:SelectedTargetDistance, meters) (&gt;L:B21_302_distance_to_go, meters)
                            (C:POI:SelectedTargetBearing, degrees) dgrd 
                            (A:PLANE HEADING DEGREES TRUE, radians) + pi + pi + 6.2832 % (&gt;L:B21_302_wp_bearing, radians)
                            quit
                        }
                        (L:B21_gpsnav_init, bool) 0 ==
                        if{
                            (A:GPS WP DISTANCE, meters) (&gt;L:B21_302_distance_to_go, meters)
                            (A:GPS WP TRUE BEARING, radians) (&gt;L:B21_302_wp_bearing, radians)
                            quit
                        }
                        (L:B21_gpsnav_wp_distance, meters) (&gt;L:B21_302_distance_to_go, meters)
                        (L:B21_gpsnav_wp_bearing, radians) (&gt;L:B21_302_wp_bearing, radians)
				    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE STF FOR CURRENT MACCREADY (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_stf, meters per second)
         **********************************************************************
         </Value></Comment>
        <Element id="expression_arrival_height">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99999.000</Minimum>
                    <Maximum>+99999.000</Maximum>
                    <Script>
                        (L:B21_302_maccready, meters per second)
                        (L:B21_302_polar_const_r, number) *
                        (L:B21_polar_stf_best, meters per second) sqr + sqrt
                        (L:B21_302_polar_adjust, number) sqrt *
                            (&gt;L:B21_302_mc_stf, meters per second)
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE POLAR SINK RATE AT MACCREADY STF (SINK RATE IS +ve)
                    (FOR ARRIVAL HEIGHT)
                    Outputs:
                        (L:B21_302_mc_sink, meters per second)
                    Inputs:
                        (L:B21_302_polar_speed_0..6
                        (L:B21_302_polar_sink_0..6
         **********************************************************************
         </Value></Comment>
        <Element>
            <Select id="expression polar sink">
                <Expression id="Expression2">
                    <Minimum>-10.000</Minimum>
                    <Maximum>10.000</Maximum>
                    <Script>
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_1, meters per second) &lt; if{
                            (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_0, meters per second) - 
                            (L:B21_302_polar_speed_1, meters per second) (L:B21_302_polar_speed_0, meters per second) - / 
                            (L:B21_302_polar_sink_1, meters per second) (L:B21_302_polar_sink_0, meters per second) - * 
                            (L:B21_302_polar_sink_0, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_2, meters per second) &lt; if{
                            (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_1, meters per second) - 
                            (L:B21_302_polar_speed_2, meters per second) (L:B21_302_polar_speed_1, meters per second) - / 
                            (L:B21_302_polar_sink_2, meters per second) (L:B21_302_polar_sink_1, meters per second) - * 
                            (L:B21_302_polar_sink_1, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_3, meters per second) &lt; if{
                            (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_2, meters per second) - 
                            (L:B21_302_polar_speed_3, meters per second) (L:B21_302_polar_speed_2, meters per second) - / 
                            (L:B21_302_polar_sink_3, meters per second) (L:B21_302_polar_sink_2, meters per second) - * 
                            (L:B21_302_polar_sink_2, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_4, meters per second) &lt; if{
                            (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_3, meters per second) - 
                            (L:B21_302_polar_speed_4, meters per second) (L:B21_302_polar_speed_3, meters per second) - / 
                            (L:B21_302_polar_sink_4, meters per second) (L:B21_302_polar_sink_3, meters per second) - * 
                            (L:B21_302_polar_sink_3, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_5, meters per second) &lt; if{
                            (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_4, meters per second) - 
                            (L:B21_302_polar_speed_5, meters per second) (L:B21_302_polar_speed_4, meters per second) - / 
                            (L:B21_302_polar_sink_5, meters per second) (L:B21_302_polar_sink_4, meters per second) - * 
                            (L:B21_302_polar_sink_4, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                            g1 
                          }
                       (L:B21_302_mc_stf, meters per second) (L:B21_302_polar_speed_5, meters per second) - 
                       (L:B21_302_polar_speed_6, meters per second) (L:B21_302_polar_speed_5, meters per second) - / 
                       (L:B21_302_polar_sink_6, meters per second) (L:B21_302_polar_sink_5, meters per second) - * 
                       (L:B21_302_polar_sink_5, meters per second) + (&gt;L:B21_302_mc_sink, meters per second)
                       :1
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE ARRIVAL HEIGHT
                Outputs: 
                    (L:B21_arrival_height, meters)
                Inputs:
                    (L:B21_302_mc_stf, meters per second)
                    (L:B21_302_mc_sink, meters per second)
         **********************************************************************
         </Value></Comment>
        <Element id="expression_arrival_height">
            <FloatPosition>0.000,0.000</FloatPosition>
            <Select id="Select">
                <Expression id="Expression2">
                    <Minimum>-99999.000</Minimum>
                    <Maximum>+99999.000</Maximum>
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
                    </Script>
                </Expression>
            </Select>
        </Element>
        <Comment><Value>*******************************************************
                    CALCULATE ACTUAL GLIDE RATIO
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
</SimBase.Document>]]
