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
* user settings supported in 'USER_SETTINGS.lua'
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
* increase available forward trim (move CG forward?)
* find way to increase lateral wheel friction on ground - maybe add force opposing side wind.

### yawstring

* DONE remove speed-based rotation animation, keep yaw swing
* try animate in 2 parts, main vs. tip
* move animation control into Lua

### nav instrument

* DONE get wind data
* get waypoint location data
* define TP zone
* design task creation
* create nav instrument reading flight plan
* add glider turnpoints to nav database
* increase font sizes
* create FMS file prompt, or use X-Plane built-in. Support v3 and v1100 FMS file formats
* add commands
  - next waypoint
  - previous waypoint

### 302 vario

* DONE update vario_302 to display arrival height to next waypoint
  - dataref sim/cockpit2/radios/indicators/gps_dme_distance_nm
* DONE auto-switch between stf, te
* DONE update averager reading on display
* DONE get a decimal point into maccready display
* separate the TE calculation into a separate module
* DONE include sim time difference in the smoothing formula
* use needle acceleration to calculate needle position for smoothing
* change smoothing to NEEDLE not the total energy calculation
* implement gust filter
* update arrivale height immediately on Maccready change (not wait for 1-sec updates)
* add commands
  - set STF mode
  - set TE mode
  - toggle STF/TE modes
  - maccready up
  - maccready down
  - volume up
  - volume down
  - volume mute

### spoilers (aka speedbrakes) / wheel brake

* Have spoilers operate parking brake when deployed 75%..100%
* Much reduce drag impact of spoilers at small openings
* DONE design airbrake indicator on panel
* DONE check meaning of DataRefs:
  - sim/cockpit2/controls/left_brake_ratio
  - sim/cockpit2/controls/right_brake_ratio
  - sim/flightmodel2/controls/speedbrake_ratio
  - sim/cockpit2/controls/parking_brake_ratio

### winter vario

* get the TE reading from a separate b21_total_energy module, shared with 302 vario
* implement gust filter
* implement rotating maccready ring

# Air Speed Indicator

* provide Knots and Km/h switch from USER_SETTINGS.lua

# Altimeter

* provide Feet, Meters switch from USER_SETTINGS.lua

### clock

* DONE implement a clock on the panel (cut-down watch perhaps)
* DONE make watch bigger

### Trim

* support command/button for 'trigger' trim, i.e. immediately set trim to current speed

### sounds

* add 'all-out' sound
* make flight wind noise more of a whitenoise hiss, lower volume

### Aerotow

* place AI aircraft in front of glider
* do graphics for tow rope
* in cockpit sound for tow-plane

