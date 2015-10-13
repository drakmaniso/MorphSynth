class "WaveFunctions"


----------------------------------------------------------------------------------------------------


WaveFunctions.names = { "Sine", "Triangle", "Pulse", "Saw", "Diode", "Gauss", "Chebyshev", "Chirp", "White Noise", "Pink Noise", "Brown Noise" }


----------------------------------------------------------------------------------------------------


WaveFunctions["Sine"] = function  (x, shape)

    x = x % 1
    if shape == 0 then
        return math.sin (2 * x * math.pi)
    else
        shape = shape + 1
        if shape > 1 then
            shape = math.pow (100, shape) / 100
        end
        local s = 1
        if x > 0.5 then
            s = -1
        end
        return s * math.pow (s * math.sin (2 * x * math.pi), shape)
    end

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Triangle"] = function (x, shape)

    shape = (shape + 1) / 2
    x = (x + 0.5 * shape) % 1
    if x < shape then
        return x / shape * 2 - 1
    else
        return (1 - x) / (1 - shape) * 2 - 1
    end

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Pulse"] = function (x, shape)

    if x % 1 < (shape + 1) / 2 then
        return 1
    else
        return -1
    end

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Saw"] = function (x, shape)

    shape = (shape + 1) / 2 - 0.5
    local p = math.pow (0.5, 1 / math.exp (shape * 10))
    x = (x + p) % 1
    return math.pow (x, math.exp (shape * 10)) * 2 - 1

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Diode"] = function (x, shape)

    local r = math.sin (x * 2 * math.pi + (math.pi / 6) * (1 + shape)) - shape
    if r < 0 then r = 0 end
    return r / (1 - shape) * 2 - 1

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Gauss"] = function (x, shape)

    shape = (shape + 1) / 2
    local p = (- math.sqrt ( - math.log (0.5) / (math.exp (shape * 8) + 5) ) + 1) / 2
    x = 2 * ((x + p) % 1) - 1
    return math.exp (-x * x * (math.exp (shape * 8) + 5)) * 2 - 1

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Chebyshev"] = function (x, shape)

    shape = (shape + 1) / 2
    shape = shape * shape * shape * 25 + 1
    local p = (math.cos (math.pi / (2 * shape)) + 1) / 2
    return math.cos (math.acos (((x + p) % 1) * 2 - 1) * shape )

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Chirp"] = function (x, shape)

    x = (x % 1) * 2 * math.pi
    shape = shape * 2
    --~ if shape < 0 then shape = shape * 2 end
    shape = math.pow (3, shape)
    return math.sin (x / 2) * math.sin (shape * x * x);

end


----------------------------------------------------------------------------------------------------


WaveFunctions["White Noise"] = function (x, shape)

    return math.random () * 2 - 1

    --~ elseif shape > 0 then
        --~ return math.random (-1, 1) * (1 - shape) + math.random (0, 1) * math.sin (2 * x * math.pi) * (shape)
    --~ else
        --~ local p = 0
        --~ if x % 1 < 0.5 then
            --~ p = 1
        --~ else
            --~ p = -1
        --~ end
        --~ return math.random (-1, 1) * (1 + shape) + math.random (0, 1) * p * (- shape)
    --~ end

end


----------------------------------------------------------------------------------------------------


WaveFunctions["Brown Noise"] = function (x, shape)

    local r = math.random () - 0.5

    WaveFunctions.brown = WaveFunctions.brown + r

    if WaveFunctions.brown < -8 or WaveFunctions.brown > 8 then
        WaveFunctions.brown = WaveFunctions.brown - r
    end

    return WaveFunctions.brown / 8

end


----------------------------------------------------------------------------------------------------


function count_trailing_zeros (num)

    local i = 0
    local n = num
    while (n % 2) == 0 and i < 16 do
        n = math.floor (n / 2)
        i = i + 1
    end

    return i

end


function WaveFunctions.initialize_random_seed (seed)

    WaveFunctions.pink_store = {0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  0, 0, 0, 0,  }
    WaveFunctions.pink = 0
    WaveFunctions.pink_count = 0
    WaveFunctions.brown = 0

    math.randomseed (seed)

end


function WaveFunctions.next_pink ()

    local k = count_trailing_zeros (WaveFunctions.pink_count)
    k = k % 16 + 1

    local prevr = WaveFunctions.pink_store[k]

    local finished = false
    repeat

        local r = math.random () - 0.5

        WaveFunctions.pink_store[k] = r

        r = r - prevr

        WaveFunctions.pink = WaveFunctions.pink + r

        if WaveFunctions.pink < -4 or WaveFunctions.pink > 4 then
            WaveFunctions.pink = WaveFunctions.pink - r
        else
            finished = true
        end

    until finished

    WaveFunctions.pink_count = WaveFunctions.pink_count + 1

    return (math.random() - 0.5 + WaveFunctions.pink) * 0.250

end


WaveFunctions["Pink Noise"] = function (x, shape)

    return WaveFunctions.next_pink ()

end

----------------------------------------------------------------------------------------------------

