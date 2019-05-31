-- B21

print("b21_gpsnav.lua loaded")

size = { 100, 89 }

-- datarefs READ
local dataref_heading_deg = globalPropertyf("sim/flightmodel/position/true_psi")

-- command callbacks from gpsnav buttons

local command_load = sasl.createCommand("b21/gpsnav/load", 
    "Sailplane GPSNAV load flightplan")

local command_view = sasl.createCommand("b21/gpsnav/view", 
    "Sailplane GPSNAV view loaded flightplan")

local command_left = sasl.createCommand("b21/gpsnav/left", 
    "Sailplane GPSNAV left-button function (e.g. prev waypoint)")

local command_right = sasl.createCommand("b21/gpsnav/right", 
    "Sailplane GPSNAV right-button function (e.g. next waypoint)")

local xplane_load_flightplan = sasl.findCommand("sim/FMS/key_load")

function clicked_load(phase)
    print("GPSNAV LOAD")
    sasl.commandOnce(xplane_load_flightplan)
    return 1
end

function clicked_view(phase)
    print("GPSNAV VIEW")
    return 1
end

function clicked_left(phase)
    print("GPSNAV LEFT")
    return 1
end

function clicked_right(phase)
    print("GPSNAV RIGHT")
    return 1
end

sasl.registerCommandHandler(command_load, 1, clicked_load)
sasl.registerCommandHandler(command_view, 1, clicked_view)
sasl.registerCommandHandler(command_left, 1, clicked_left)
sasl.registerCommandHandler(command_right, 1, clicked_right)

local font = sasl.gl.loadFont ( "fonts/UbuntuMono-Regular.ttf" )
--local green = { 0.0, 1.0, 0.0, 1.0 }
local black = { 0.0, 0.0, 0.0, 1.0 }

local background_img = sasl.gl.loadImage("images/gpsnav_background.png")

-- bearing_image contains 7 x BEARING images, each 79x14, total 553x14
-- where index 0 = turn hard left, 3 = ahead, 6 = hard right
local bearing_img = sasl.gl.loadImage("images/gpsnav_bearing.png")

local bearing_index = 3

local heading_to_wp_deg = 0.0 -- debug this will be calculated from flightplan waypoint

function calculate_bearing_index()
    local heading_delta_deg = get(dataref_heading_deg) - heading_to_wp_deg
    local left_deg
    local right_deg
    if heading_delta_deg > 0
    then
        left_deg = heading_delta_deg
        right_deg = 360 - heading_delta_deg
    else
        left_deg = heading_delta_deg + 360
        right_deg = -heading_delta_deg
    end
    local turn_deg
    if left_deg < right_deg
    then
        turn_deg = -left_deg
    else
        turn_deg = right_deg    
    end
    if turn_deg > 70 then bearing_index = 6
    elseif turn_deg > 40 then bearing_index = 5
    elseif turn_deg > 20 then bearing_index = 4
    elseif turn_deg > -20 then bearing_index = 3
    elseif turn_deg > -40 then bearing_index = 2
    elseif turn_deg > -70 then bearing_index = 1
    else bearing_index = 0
    end
end --calculate_bearing_index

function update()
    calculate_bearing_index()
end --update


function draw()
    -- logInfo("gpsnav draw called")
    sasl.gl.drawTexture(background_img, 0, 0, 100, 89) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    --                                        size isBold isItalic     
    sasl.gl.drawText(font,5,70, "TO: OXF", 14, true, false, TEXT_ALIGN_LEFT, black)

    sasl.gl.drawTexturePart(bearing_img, 10, 50, 79, 14, bearing_index * 79, 0, 79, 14)

    sasl.gl.drawText(font,5,10, "ARRIVE: 1240", 12, true, false, TEXT_ALIGN_LEFT, black)
end

