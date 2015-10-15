_AUTO_RELOAD_DEBUG = function()
end

math.randomseed (os.clock ())

require "MorphSynth"


renoise.tool():add_menu_entry {
    name = "Instrument Box:MorphSynth Instrument...",
    invoke = function () MorphSynth () end
}
