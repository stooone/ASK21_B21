-- B21

print("b21_gpsnav.lua loaded")

-- WRITES these shared variables:
--
-- project_settings.gpsnav_wp_distance_m
-- project_settings.gpsnav_wp_heading_deg
-- project_settings.gpsnav_wp_altitude_m
--

size = { 100, 89 }

local geo = require "b21_geo" -- contains useful geographic function like distance between lat/longs

-- datarefs READ
local dataref_heading_deg = globalPropertyf("sim/flightmodel/position/true_psi") -- aircraft true heading
local dataref_latitude = globalProperty("sim/flightmodel/position/latitude") -- aircraft latitude
local dataref_longitude = globalProperty("sim/flightmodel/position/longitude") -- aircraft longitude
local dataref_time_s = globalPropertyf("sim/network/misc/network_time_sec") -- time in seconds

M_TO_MI = 0.000621371
FT_TO_M = 0.3048
M_TO_FT = 1.0 / FT_TO_M
DEG_TO_RAD = 0.0174533

-- e.g { { type = 1, ref = "X1N7", alt = 375.0 (note METERS), lat = 40.971146, lng = -74.997475 }, ..}
local task = { }

local task_index = 0 -- which task entry is current

local wp_point = { }

local prev_click_time_s = 0.0 -- time button was previously clicked (so only one action per click)

-- gpsnav vars shared with other instruments (e.g. 302 vario)
project_settings.gpsnav_wp_distance_m = 0.0 -- distance to next waypoint in meters

project_settings.gpsnav_wp_heading_deg = 0.0 -- heading (true) to next waypoint in degrees

project_settings.gpsnav_wp_altitude_m = 0.0 -- altitude MSL of next waypoint in meters

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

-- delete all waypoints in FMS
function clear_fms()
    print("GPSNAV CLEAR")
    local fms_count = sasl.countFMSEntries()
    for i = fms_count - 1, 0, -1
    do
        sasl.clearFMSEntry(i) -- remove last entry (shortens flight plan)
        print("GPSNAV deleted wp ",i)
    end
    task = {}
    task_index = 0
end

-- set waypoint to task[i]
function set_waypoint(i)
-- e.g  { type = 1, ref = "X1N7", alt = 375.0 (METERS), lat = 40.971146, lng = -74.997475 }
    if i > 0 and i <= #task
    then
        task_index = i
        wp_point = { lat = task[task_index].lat, lng = task[task_index].lng }
        project_settings.gpsnav_wp_altitude_m = task[task_index].alt -- altitude MSL of next waypoint in meters
    end
end

function clicked_load(phase)
    if get(dataref_time_s) > prev_click_time_s + 2.0 and phase == SASL_COMMAND_BEGIN
    then
        prev_click_time_s = get(dataref_time_s)
        print("GPSNAV LOAD")
        clear_fms() -- remove existing waypoints
        sasl.commandOnce(xplane_load_flightplan)
    end
    return 0
end

function clicked_view(phase)
    print("GPSNAV VIEW")
    return 1
end

function clicked_left(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and task_index > 1 and phase == SASL_COMMAND_BEGIN
    then
        print("GPSNAV LEFT")
        prev_click_time_s = get(dataref_time_s)
        set_waypoint(task_index - 1)
    end
    return 1
end

function clicked_right(phase)
    if get(dataref_time_s) > prev_click_time_s + 0.2 and task_index < #task and phase == SASL_COMMAND_BEGIN
    then
        print("GPSNAV RIGHT")
        prev_click_time_s = get(dataref_time_s)
        set_waypoint(task_index + 1)
    end
    return 1
end

sasl.registerCommandHandler(command_load, 0, clicked_load)
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

-- calculate index into bearing PNG panel image to display correct turn indication
function update_bearing_index()
    local heading_delta_deg = get(dataref_heading_deg) - project_settings.gpsnav_wp_heading_deg
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
    elseif turn_deg > 10 then bearing_index = 4 
    elseif turn_deg > -10 then bearing_index = 3 -- center
    elseif turn_deg > -40 then bearing_index = 2
    elseif turn_deg > -70 then bearing_index = 1
    else bearing_index = 0
    end
end --calculate_bearing_index

-- update the shared variables for wp bearing and distance
function update_wp_distance_and_heading()
    if #task ~= 0
    then
        local aircraft_point = { lat= get(dataref_latitude),
                                lng= get(dataref_longitude) 
                            }
        
        project_settings.gpsnav_wp_distance_m = geo.get_distance(aircraft_point, wp_point)

        project_settings.gpsnav_wp_heading_deg = geo.get_bearing(aircraft_point, wp_point)
    end
end

-- detect when FMS has loaded a new flightplan
function update_fms()
    local fms_count = sasl.countFMSEntries()
    if fms_count <= #task
    then
        return
    end

    print("gpsnav fms_count",fms_count)
    
    task = {}

    for i=0, fms_count-1
    do
        local wp_type, wp_name, wp_id, wp_altitude, wp_latitude, wp_longitude = sasl.getFMSEntryInfo(i)
        print("GPSNAV["..i.."]",wp_type, wp_name, wp_id, wp_altitude, wp_latitude, wp_longitude)
        table.insert(task,{ type = wp_type, 
                            ref =  wp_name, 
                            alt = wp_altitude * FT_TO_M,
                            lat = wp_latitude, 
                            lng = wp_longitude
                        })
    end

    set_waypoint(1)
end

function update()
    update_wp_distance_and_heading()
    update_bearing_index()
    update_fms()
end --update


function draw()
    -- logInfo("gpsnav draw called")
    sasl.gl.drawTexture(background_img, 0, 0, 100, 89) -- draw background texture
    -- sasl.gl.drawLine(0,0,100,100,green)

    -- "1/5: 1N7"
    local top_string
    if #task == 0
    then
        top_string = " LOAD TASK"
    else
        top_string = task_index .. "/" .. #task .. ":" .. task[task_index].ref
    end

    -- "DIST: 37.5km"
    local distance_string
    if project_settings.DISTANCE_UNITS == 0 -- (0=mi, 1=km)
    then
        distance_string = (math.floor(project_settings.gpsnav_wp_distance_m * M_TO_MI * 10.0) / 10.0) .. " MI"
    else
        distance_string = (math.floor(project_settings.gpsnav_wp_distance_m / 100.0) / 10.0) .. " KM"
    end
    local mid_string = distance_string

    local altitude_string
    if project_settings.ALTITUDE_UNITS == 0 -- (0=feet, 1=meters)
    then
        altitude_string = math.floor(project_settings.gpsnav_wp_altitude_m * M_TO_FT) .. " FT"
    else
        altitude_string = math.floor(project_settings.gpsnav_wp_altitude_m) .. " M"
    end
    local bottom_string = altitude_string

    --  TOP STRING                         size isBold isItalic     
    sasl.gl.drawText(font,5,70, top_string, 16, true, false, TEXT_ALIGN_LEFT, black)

    -- BEARING GRAPHIC
    sasl.gl.drawTexturePart(bearing_img, 10, 45, 79, 14, bearing_index * 79, 0, 79, 14)

    -- MIDDLE STRING
    sasl.gl.drawText(font,5,25, mid_string, 18, true, false, TEXT_ALIGN_LEFT, black)

    -- BOTTOM STRING
    sasl.gl.drawText(font,5,5, bottom_string, 18, true, false, TEXT_ALIGN_LEFT, black)
    
end

 