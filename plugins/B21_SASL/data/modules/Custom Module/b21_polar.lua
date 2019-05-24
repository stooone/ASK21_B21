
print("B21 polar.lua starting")

-- polar sink curve, speeds in km/h, sink in m/s
-- ASK21 B21
polar = createProperty({
    { 65.0, 0.8 },
    { 70.0, 0.75 },
    { 80.0, 0.7 },
    { 90.0, 0.76 },
    { 100.0, 0.83 },
    { 120.0, 1.2 },
    { 140.0, 1.8 },
    { 160.0, 2.4 },
    { 180.0, 3.5 },
    { 200.0, 5.0 },
    { 250.0, 10.0 } -- guess, off end of published polar
})
