-- Check XP is an integer
function IsInt(xp)
    xp = tonumber(xp)
    if xp and xp == math.floor(xp) then
        return true
    end
    return false
end
