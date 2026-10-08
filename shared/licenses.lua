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

-- Promotion rules live in spz-progression/config.lua (Config.Rules). The class
-- letter is derived from rank points; nothing gates cars or classes on it.
