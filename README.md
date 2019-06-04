# X-Plane glider ASK21 - B21 updated

## Done so far

* Flight model updated (stall, polar L/D, sensitivity)
* TE algorithm implemented in Lua plugin (works xlua, sasl)
* Winter vario programmed for TE
* Cambridge 302 vario implemented with TE, Netto, Speed-to-Fly, adjustable maccready
* 57mm vario added for Netto
* vario sound plugin created
  - volume control
  - 'quiet band' parameters
* user settings supported in 'settings.lua'
* wheel brake action range set to 75%..100% airbrakes
* sounds improved
  - brakes closed
  - rolling on runway
  - rolling on grass
  - airspeed wind

## dev checklist

Checklist of things still to be done.

### flight model

* reduce sensitivity in yaw
* maybe improve stall behaviour

### yawstring

* remove rotation animation
* try animate in 2 parts, main vs. tip
* move animation control into Lua

### nav instrument

* get wind data
* get waypoint location data
* define TP zone
* design task creation
* create nav instrument reading flight plan
* add glider turnpoints to nav database
* add commands
  - next waypoint
  - previous waypoint

### 302 vario

* update vario_302 to display arrival height to next waypoint
  - dataref sim/cockpit2/radios/indicators/gps_dme_distance_nm
* auto-switch between stf, te
* update averager reading on display
* get a decimal point into maccready display
* include sim time difference in the smoothing formula
* implement gust filter
* add commands
  - set STF mode
  - set TE mode
  - toggle STF/TE modes
  - maccready up
  - maccready down
  - volume up
  - volume down
  - volume mute

### spoilers / wheel brake

* design airbrake indicator on panel
* check meaning of DataRefs:
  - sim/cockpit2/controls/left_brake_ratio
  - sim/cockpit2/controls/right_brake_ratio
  - sim/flightmodel2/controls/speedbrake_ratio
  - sim/cockpit2/controls/parking_brake_ratio

### winter vario

* slave the TE reading from the 302 vario
* implement gust filter
* implement rotating maccready ring

### clock

* implement a clock on the panel (cut-down watch perhaps)

### sounds

* add 'all-out' sound

### Aerotow

* place AI aircraft in front of glider
* do graphics for tow rope
* in cockpit sound for tow-plane

### Winch

* add automated winch script
  - sounds incl wings level, all out, cable break

### ridge lift

* check strength as implemented in X-Plane

### thermals

* check strength and size as implemented in X-Plane

