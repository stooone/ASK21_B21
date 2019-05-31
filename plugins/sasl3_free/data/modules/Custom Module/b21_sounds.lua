-- B21

-- #################################################
-- Vario sound controlled by this DataRef:
climbrate = createGlobalPropertyf("b21/vario_sound_fpm", 0.0, false, true, true)
-- #################################################

local QUIET_CLIMB = project_settings.QUIET_CLIMB
local QUIET_SINK = project_settings.QUIET_SINK
local prev_volume = project_settings.VARIO_VOLUME

local spoilers_unlock = loadSample(sasl.getAircraftPath()..'/sounds/systems/BrakesOut.wav')

local spoilers_lock = loadSample(sasl.getAircraftPath()..'/sounds/systems/BrakesIn.wav')

local sounds = { climb = loadSample(sasl.getAircraftPath()..'/sounds/alert/vario_climb.wav'),
				 sink = loadSample(sasl.getAircraftPath()..'/sounds/alert/vario_sink.wav')
               }

defineProperty("spoiler_ratio", globalPropertyf("sim/cockpit2/controls/speedbrake_ratio")) -- get value of spoiler lever setting
pause = globalPropertyf("sim/time/paused") -- check if sim is paused
DATAREF_VOLUME = createGlobalPropertyi("b21/vario_sound_volume", project_settings.VARIO_VOLUME, false, true, false) -- dataref for the "off/volume" switch

local spoiler_init = 0 -- flag to ensure spoiler sounds played once on open/close

setSampleGain(spoilers_lock, 500)
setSampleGain(spoilers_unlock, 500)

setSampleGain(sounds.climb, project_settings.VARIO_VOLUME)
setSampleGain(sounds.sink, project_settings.VARIO_VOLUME)

--playSample(spoilers_unlock)

function update_spoilers()
	-------------- generate airbrake lock / unlock sounds
	if get(spoiler_ratio) > 0.03 and spoiler_init == 0 
	then 
		playSample(spoilers_unlock, false)
        spoiler_init = 1
        return
	end

	if get(spoiler_ratio) < 0.03 and spoiler_init == 1 
	then
		playSample(spoilers_lock, false)
		spoiler_init = 0
	end
end

function update_volume()
	local new_volume = get(DATAREF_VOLUME)

	if new_volume ~= prev_volume
	then
        if new_volume == 0
        then
            stopSample(sound.sink)
            stopSample(sound.climb)
        else
		    setSampleGain(sounds.climb, new_volume)
            setSampleGain(sounds.sink, new_volume)
        end
        prev_volume = new_volume
	end
end --update_volume()

-- if either climb or sink sounds are playing, stop them
function stop_sounds()
	if isSamplePlaying(sounds.climb)
	then
		stopSample(sounds.climb) 
	end
	if isSamplePlaying(sounds.sink)
	then
		stopSample(sounds.sink) 
	end
end

-- adjust which wav file is playing at what pitch
function update_climb(vario_climbrate)

    local pitch -- pitch rate required by setSamplePitch (1000 = normal)

	-- if paused then kill sound and return
	if (get(pause) == 1) or (prev_volume == 0)
	then
		stop_sounds()
		return
	end

	-- if the climbrate is above the dead band, play sounds.climb

    if vario_climbrate > QUIET_CLIMB
    then
        if isSamplePlaying(sounds.sink)
        then
            stopSample(sounds.sink)
        end
        -- play climb sound
        pitch = math.floor(vario_climbrate / 2.0) + 650.0
        setSamplePitch(sounds.climb, pitch)
        if not isSamplePlaying(sounds.climb)
        then
            playSample(sounds.climb, true) -- looping
        end
        return
    elseif vario_climbrate < QUIET_SINK
	then
        if isSamplePlaying(sounds.climb)
        then
            stopSample(sounds.climb)
        end
        -- play sink sound
        pitch = math.floor( -39000.0 / vario_climbrate + 235.0 )
        setSamplePitch(sounds.sink, pitch)
        if not isSamplePlaying(sounds.sink)
        then
            playSample(sounds.sink, true) -- looping
        end
        return
    else
        -- otherwise, in quiet band, stop both sounds
        if isSamplePlaying(sounds.climb)
        then
            stopSample(sounds.climb)
        end
        if isSamplePlaying(sounds.sink)
        then
            stopSample(sounds.sink)
        end
    end
end -- update_climb()

-- The main UPDATE function
function update()
	update_spoilers()
	update_volume()
	update_climb(get(climbrate))
end --update()

