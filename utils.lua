

function renoise_note_of (note, octave)

    return (octave - 1) * 12 + (note - 1)

end


function frequency_of_renoise_note (note)

    -- In the formula, A4 is 49
    -- For the value calculated above, A4 is 57
    local n = note - 57 + 49

    return 440 * math.pow(2, (n - 49) / 12)

end

function name_of_renoise_note (note)

    local n = math.floor (note % 12) + 1

    local o = math.floor (note / 12)

    local names = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-", }

    return names[n] .. o

end

------------------------------------------------------------------------------------------------------

function to_exp_display (v, max)

    return math.log (9 * (v / max) + 1) / math.log (10)

end

function from_exp_display (v, max)

    return max * (10 ^ v - 1) / 9

end
