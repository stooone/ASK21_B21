#dataref_smoke = createGlobalPropertyf("b21/smoke", 0.0, false, true, true)
dataref_smoke = globalPropertyi("sim/cockpit/weapons/missiles_armed")

command_smoke_toggle = sasl.createCommand("b21/smoke/toggle", "Toggle wingtip smoke emitters")

local DATAREF_TIME_S = globalPropertyf("sim/network/misc/network_time_sec")

local command_time_s = 0.0
local command_trim = 0.0
local prev_trim_time_s = 0.0
local prev_trim_time_s = 0.0

function clicked_smoke_toggle(phase)
  local time_now_s = get(DATAREF_TIME_S)
  if time_now_s > command_time_s + 0.2 and phase == SASL_COMMAND_BEGIN
  then
      
    command_time_s = time_now_s
    if get(dataref_smoke) == 0
    then
      set(dataref_smoke,1)
	  print("smoke on")
    else
      set(dataref_smoke,0)
	  print("smoke off")
	  end
  end
  return 0
end

sasl.registerCommandHandler(command_smoke_toggle, 0, clicked_smoke_toggle)