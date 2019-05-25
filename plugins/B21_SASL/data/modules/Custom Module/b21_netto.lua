-- B21
-- ASK21 Netto Vario calculation
-- Subtract the normal glider sink from the actual sink rate to estimate air sink rate.
-- 
print("B21 b21_netto.lua starting")

-- ----------------------------------------------
-- DATAREFS
-- the dataref we will WRITE to, to position the needle in the gauge
b21_netto_mps = createGlobalPropertyf("b21/ask21/vario_netto_mps", 0.0, false, true, true) -- the netto compensated vario in meter/sec
b21_debug_polar_sink_mps = createGlobalPropertyf("b21/ask21/debug_polar_sink_mps", 0.0, false, true, true) -- the netto compensated vario in meter/sec
b21_debug_polar_p1_mps = createGlobalPropertyf("b21/ask21/debug_polar_p1_mps", 0.0, false, true, true) -- the netto compensated vario in meter/sec
b21_debug_polar_p2_mps = createGlobalPropertyf("b21/ask21/debug_polar_p2_mps", 0.0, false, true, true) -- the netto compensated vario in meter/sec

-- the datarefs we will READ:
b21_total_energy_mps = globalPropertyf("b21_soaring/total_energy_mps")
sim_speed_kts = globalPropertyf("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
--
-- ----------------------------------------------
local SPEED = 1 -- indexes into polar { x, y } elements
local SINK = 2
-- polar.lua defines a var:
--    polar = { {speed1, sink1}, {speed2,sink2}, ...} for the glider polar
--import("polar.lua")
-- polar sink curve, speeds in km/h, sink in m/s
-- ASK21 B21
polar = {
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

print("polar loaded "..polar[1][1]) -- debug should print 65
-- ----------------------------------------------

-- calcular polar sink in m/s for given airspeed in km/h
function sink_mps(speed_kph)
local prev_point = { 0, 0 } -- arbitrary starting polar point (for speed < polar[1][SPEED])
	for i, point in pairs(polar)
	do
		if ( speed_kph < point[SPEED])
		then
			return interp(speed_kph, prev_point, point)
		end
		prev_point = point
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
--------------------------------- REGULAR RUNTIME ---------------------------------
function update()
	
	-- get current speed in km/h
	local speed_kph = get(sim_speed_kts) * 1.852

	set(b21_debug_polar_sink_mps, sink_mps(speed_kph))

	set(b21_netto_mps, get(b21_total_energy_mps) + sink_mps(speed_kph))
		
end -- after_physics
