-- B21

local QUIET_CLIMB = 10 -- dead band -110 fpm .. +10 fpm
local QUIET_SINK = -110 -- vario will be silent in this band

local spoilers_unlock = loadSample(sasl.getAircraftPath()..'/sounds/systems/BrakesOut.wav')

local spoilers_lock = loadSample(sasl.getAircraftPath()..'sounds/systems/BrakesIn.wav')

local sounds = { climb = loadSample(sasl.getAircraftPath()..'sounds/alert/vario_climb.wav'),
				 sink = loadSample(sasl.getAircraftPath()..'sounds/alert/vario_descend.wav')
}

defineProperty("spoiler_ratio", globalPropertyf("sim/cockpit2/controls/speedbrake_ratio")) -- get value of spoiler lever setting
pause = globalPropertyf("sim/time/paused") -- check if sim is paused
volume_switch = globalPropertyi("sim/auriel/acoustic_switch") -- dataref for the "off/volume" switch
climbrate = globalPropertyf("b21_soaring/total_energy_fpm") -- 'smoothed' vario dataref, will be used to set pitch of vario sound

local status = 0

setSampleGain(spoilers_lock, 500)
setSampleGain(spoilers_unlock, 500)

local volume = 0

function update_spoilers()
	-------------- generate airbrake lock / unlock sounds
	if get(spoiler_ratio) > 0.03 and status == 0 
	then 
		playSample(spoilers_unlock, 0)
        status = 1
        return
	end

	if get(spoiler_ratio) < 0.03 and status == 1 
	then
		playSample(spoilers_lock, 0)
		status = 0
	end
end

function update_volume()
	local new_volume = 100 -- get(volume_switch) * 100

	if new_volume ~= volume
	then
        volume = new_volume
        if volume == 0
        then
            stopSample(sound.sink)
            stopSample(sound.climb)
        else
		    setSampleGain(sounds.climb, volume)
            setSampleGain(sounds.sink, volume)
        end
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
	if (get(pause) == 1) or (volume == 0)
	then
		stop_sounds()
		return
	end

	-- if the climbrate is above the dead band, play sounds.climb

    if vario_climbrate < QUIET_CLIMB
    then
        if isSamplePlaying(sounds.climb)
        then
            stopSample(sounds.climb)
        end
    else
        -- play climb sound
        pitch = math.floor(vario_climbrate / 2.0) + 650.0
        setSamplePitch(sounds.climb, pitch)
        if not isSamplePlaying(sounds.climb)
        then
            playSample(sounds.climb, 1) -- looping
        end
        return
    end

	if vario_climbrate > QUIET_SINK
	then
        if isSamplePlaying(sounds.sink)
        then
            stopSample(sounds.sink)
        end
    else
        -- play sink sound
        pitch = math.floor( -39000.0 / vario_climbrate + 235.0 )

        setSamplePitch(sounds.sink, pitch)

        if not isSamplePlaying(sounds.sink)
        then
            playSample(sounds.sink, 1) -- looping
        end
    end
end -- update_climb()

-- The main UPDATE function
function update()
	update_spoilers()
	update_volume()
	update_climb(get(climbrate))
end --update()

