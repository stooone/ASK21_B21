-- B21
-- ASK21 Netto Vario calculation
-- Subtract the normal glider sink from the actual sink rate to estimate air sink rate.
-- 
print("B21 b21_netto.lua starting")
function aircraft_load()
	print("B21_netto - aircraft loaded")
end
-- ----------------------------------------------
-- DATAREFS
-- the dataref we will WRITE to, to position the needle in the gauge
b21_netto_mps = create_dataref("b21/ask21/vario_netto_mps","number") -- the netto compensated vario in meter/sec

-- the datarefs we will READ:
b21_total_energy_mps = find_dataref("b21_soaring/total_energy_mps")
sim_speed_kts = find_dataref("sim/cockpit2/gauges/indicators/airspeed_kts_pilot")
--
-- ----------------------------------------------
local SPEED = 1 -- indexes into polar { x, y } elements
local SINK = 2
-- polar.lua defines a var:
--    polar = { {speed1, sink1}, {speed2,sink2}, ...} for the glider polar
dofile("polar.lua")
print("polar loaded "..polar[1][1]) -- debug should print 65
-- ----------------------------------------------

-- calcular polar sink in m/s for given airspeed in km/h
function sink_mps(speed_kph)
local prev_point = { 0, 0 } -- arbitrary starting polar point (for speed < polar[1][SPEED])
	for i, point in pairs(polar)
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
	local ratio = speed / (p2[SPEED] - p1[SPEED])
	return p1[SINK] + ratio * (p2[SINK]-p1[SINK])

--------------------------------- REGULAR RUNTIME ---------------------------------
function after_physics()
	
	-- get current speed in km/h
	local speed_kph = sim_speed_kts * 1.852

	b21_netto_mps = b21_total_energy_mps - sink_mps(speed_kph)
		
end -- afterr_physics
