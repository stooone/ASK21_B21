-- B21

sasl.options.setAircraftPanelRendering(true)
sasl.options.setInteractivity(true)
sasl.options.set3DRendering(false)
sasl.options.setRenderingMode2D(SASL_RENDER_2D_DEFAULT)
sasl.options.setPanelRenderingMode(SASL_RENDER_PANEL_DEFAULT)
panel2d = true

size = { 2048, 2048 }

project_settings = { }

-- USER SETTINGS (e.g. vario sound volume) IN "Custom Modules/settings.lua"
include(sasl.getAircraftPath().."/USER_SETTINGS.lua")

-- put units values into DataRefs so they can be read by gauges
createGlobalPropertyi("b21/ask21/units_vario",project_settings.VARIO_UNITS,false,true,true)
createGlobalPropertyi("b21/ask21/units_speed",project_settings.SPEED_UNITS,false,true,true)
createGlobalPropertyi("b21/ask21/units_altitude",project_settings.ALTITUDE_UNITS,false,true,true)

components = { 
                b21_sounds {},
                b21_vario_302 {},
                b21_vario_57 {},
                b21_airbrakes {},
	            b21_gpsnav { 
                   position = { 462, 275, 100, 89}
                }
             }

function draw()
    drawAll(components)
end
