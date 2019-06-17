# X-Plane glider ASK21 - B21 updated

### General

* DONE create waggle-ailerons command trigger - use for wings-level
* DEFERRED create waggle-rudder command trigger - use for aerotow/winch launch "all-out"
* DONE implement "b21/wings_level" command

### TE Calculation

* DONE TE algorithm implemented in Lua plugin (works xlua, sasl)

### winter vario

* DONE get the TE reading from a separate b21_total_energy module, shared with 302 vario
* DONE implement gust filter
* DONE implement rotating maccready ring
* DONE add units to vario face

### flight model

* DONE Flight model updated (stall, polar L/D, sensitivity)
* reduce sensitivity in yaw
* maybe improve stall behaviour
* DONE increase available forward trim (move CG forward?)
* DONE find way to increase lateral wheel friction on ground - maybe add force opposing side wind.

### yawstring

* DONE remove speed-based rotation animation, keep yaw swing
* DEFERRED try animate in 2 parts, main vs. tip
* DONE move animation control into Lua

### nav instrument

* DONE get wind data
* DONE get waypoint location data
* DONE design task creation
* DONE create nav instrument reading flight plan
* DEFERRED add glider turnpoints to nav database
* DEFERRED define TP zone
* DONE increase font sizes
* DONE create FMS file prompt, or use X-Plane built-in. Support v3 and v1100 FMS file formats
* DONE add commands
  - next waypoint
  - previous waypoint
* DONE bugfix correct use of ground track dataref for heading arrows (thanks Chris)
* DONE get waypoint elevation from X-Plane terrain probe

### 302 vario

* DONE update vario_302 to display arrival height to next waypoint
  - dataref sim/cockpit2/radios/indicators/gps_dme_distance_nm
* DONE auto-switch between stf, te
* DONE update averager reading on display
* DONE get a decimal point into maccready display
* DONE separate the TE calculation into a separate module
* DONE include sim time difference in the smoothing formula
* DEFERRED use needle acceleration to calculate needle position for smoothing
* DEFERRED change smoothing to NEEDLE not the total energy calculation
* DONE implement gust filter
* update arrival height immediately on Maccready change (not wait for 1-sec updates)
* add commands
  - set STF mode
  - set TE mode
  - toggle STF/TE modes
  - maccready up
  - maccready down
  - volume up
  - volume down
  - volume mute

### 57mm vario

* DONE implement NETTO
* DONE add units to vario face
* DONE fade reading to zero as airspeed reduces

### spoilers (aka speedbrakes) / wheel brake

* DONE Have spoilers operate parking brake when deployed 75%..100%
* Much reduce drag impact of spoilers at small openings
* DONE wheel brake action range set to 75%..100% airbrakes
* DONE design airbrake indicator on panel
* DONE check meaning of DataRefs:
  - sim/cockpit2/controls/left_brake_ratio
  - sim/cockpit2/controls/right_brake_ratio
  - sim/flightmodel2/controls/speedbrake_ratio
  - sim/cockpit2/controls/parking_brake_ratio


# Air Speed Indicator

* DONE provide Knots and Km/h switch from USER_SETTINGS.lua

# Altimeter

* DONE provide Feet, Meters switch from USER_SETTINGS.lua

### clock

* DONE implement a clock on the panel (cut-down watch perhaps)
* DONE make watch bigger

### Trim

* DONE support command/button for 'trigger' trim, i.e. immediately set trim to current speed

### sounds

* DONE vario sound plugin created
  - volume control
  - 'quiet band' parameters
* DONE sounds improved
  - brakes closed
  - rolling on runway
  - rolling on grass
  - airspeed wind
* DEFERRED add 'all-out' sound
* DONE make flight wind noise more of a whitenoise hiss, lower volume
* DONE add alternate sound for STF vs TE

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

### General

* DONE user settings supported in 'USER_SETTINGS.lua'
