-- shared/licenses.lua

SPZ = SPZ or {}

SPZ.License = {
    C = 0,
    B = 1,
    A = 2,
    S = 3,
}

SPZ.LicenseNames = {
    [0] = "Class C — Street",
    [1] = "Class B — Sport",
    [2] = "Class A — Pro",
    [3] = "Class S — Elite",
}

SPZ.LicenseRequirements = {
    [1] = { points = 500,  top3 = 5,  min_sr = 1.0 },  -- to unlock B
    [2] = { points = 1000, top3 = 8,  min_sr = 1.5 },  -- to unlock A
    [3] = { points = 2000, top3 = 12, min_sr = 2.0 },  -- to unlock S
}
