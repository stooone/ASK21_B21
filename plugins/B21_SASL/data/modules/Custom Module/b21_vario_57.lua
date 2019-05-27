-- B21

-- the needle on the vario_57 gauge listens to this DataRef
vario_57_needle = createGlobalPropertyf("b21/ask21/vario_57/needle_fpm", 0.0, false, true, true)
netto_fpm = globalPropertyf("b21/ask21/netto_fpm")
-- 'Slave' the netto_fpm from the 302 gauge and write to the vario_57 needle
function update()
    set(vario_57_needle, get(netto_fpm))
end
