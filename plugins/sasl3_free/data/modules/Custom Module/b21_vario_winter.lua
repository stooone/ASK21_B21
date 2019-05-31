-- B21

print("b21_vario_winter starting")

-- the needle on the vario_57 gauge listens to this DataRef
local vario_winter_needle = createGlobalPropertyf("b21/vario_winter/needle_fpm", 0.0, false, true, true)
local netto_fpm = globalPropertyf("b21/total_energy_fpm")
-- 'Slave' the netto_fpm from the 302 gauge and write to the vario_57 needle
function update()
    set(vario_winter_needle, get(netto_fpm))
end
