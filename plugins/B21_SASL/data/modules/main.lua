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
include("settings.lua")

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
