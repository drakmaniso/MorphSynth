class "MorphSynthWindow"

require "WaveFunctions"

local status = nil

----------------------------------------------------------------------------------------------------


function MorphSynthWindow:__init (morph_synth)

    self.vb = renoise.ViewBuilder ()

    self.morph_synth = morph_synth

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:show_dialog ()

    if self.dialog and self.dialog.visible then
        self.dialog:show ()
        return
    end

    self.nb_waveforms = 0

    if not self.dialog_content then
        self.dialog_content = self:gui ()
    end

    local kh = function (d, k) return self:key_handler (d, k) end
    self.dialog = renoise.app():show_custom_dialog ("MorphSynth", self.dialog_content, kh)

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:key_handler (dialog, key)

    if key.modifiers == "" and key.name == "esc" then

        dialog:close()

    else

        return key

    end

end


----------------------------------------------------------------------------------------------------

MorphSynthWindow.sample_size_names = { "16k", "32k", "64k", "128k", "256k", "512k" }
MorphSynthWindow.sample_size_values = { 16*1024, 32*1024, 64*1024, 128*1024, 256*1024, 512*1024 }

MorphSynthWindow.sample_rate_names = { "11025", "22050", "32000", "44100", "48000", "88200", "96000", "44000" }
MorphSynthWindow.sample_rate_values = { 11025, 22050, 32000, 44100, 48000, 88200, 96000, 44000 }

MorphSynthWindow.bit_depth_names = { "16", "24", "32", }
MorphSynthWindow.bit_depth_values = { 16, 24, 32, }

MorphSynthWindow.nb_channels_names = { "Mono", "Stereo", }
MorphSynthWindow.nb_channels_values = { 1, 2, }

MorphSynthWindow.section_names = { "Carrier", "FM Modulator 1", "FM Modulator 2", "Ring Modulator", }
MorphSynthWindow.section_carrier = 1
MorphSynthWindow.section_fm1 = 2
MorphSynthWindow.section_fm2 = 3
MorphSynthWindow.section_ring = 4

MorphSynthWindow.nna_names = { "Cut", "Note Off", "Continue" }

MorphSynthWindow.fm_algorithm_names = { "Parallel", "Serie" }

MorphSynthWindow.durations_unit_names = { "ms", "s", "osc" }


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:generate_samples ()

    self:update_parameters (self.vb.views.voice.value, self.vb.views.voice_section.value)

    self.vb.views.status.text = "Generating sample..."
    self.morph_synth:generate_samples ()
    self.vb.views.status.text = "Sample generated."

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:update_parameters (voice_index, voice_section_index)

    local views = self.vb.views

    self.morph_synth.sample_rate = self.sample_rate_values[views.sample_rate.value]
    self.morph_synth.bit_depth = self.bit_depth_values[views.bit_depth.value]

    self.morph_synth.first_note = views.first_note.value
    self.morph_synth.last_note = views.last_note.value
    self.morph_synth.keyzones_step = views.keyzones_step.value

    local voice = self.morph_synth.voices[voice_index]

    voice.volume = views.volume.value + 1
    voice.panning = math.floor (views.panning.value + 0.5)
    voice.transpose = math.floor (views.transpose.value + 0.5)
    voice.finetune = views.finetune.value
    voice.seed = views.seed.value
    voice.new_note_action = MorphSynthWindow.nna_names[views.new_note_action.value]
    voice.fm_algorithm = MorphSynthWindow.fm_algorithm_names[views.fm_algorithm.value]
    voice.autofade = views.autofade.value == 2
    voice.envelopes = views.envelopes.value

    voice.loop_mode = views.loop_mode.value
    voice.loop_from = views.loop_from.value
    voice.loop_to = views.loop_to.value

    if voice_section_index == MorphSynthWindow.section_carrier then
        self:update_voice_section_parameters (voice.carrier, voice_section_index)
    elseif voice_section_index == MorphSynthWindow.section_fm1 then
        self:update_voice_section_parameters (voice.frequency_modulator_1, voice_section_index)
    elseif voice_section_index == MorphSynthWindow.section_fm2 then
        self:update_voice_section_parameters (voice.frequency_modulator_2, voice_section_index)
    elseif voice_section_index == MorphSynthWindow.section_ring then
        self:update_voice_section_parameters (voice.ring_modulator, voice_section_index)
    end

end

function MorphSynthWindow:update_voice_section_parameters (section, section_index)

    local views = self.vb.views

    for i = 1, self.nb_waveforms do
        section.durations[i] = { }
        if i < self.nb_waveforms then
            section.durations[i].unit = MorphSynthWindow.durations_unit_names[views["duration_unit_" .. i].value]
            if views["duration_unit_" .. i].value == 1 then
                section.durations[i].value = math.floor (views["duration_" .. i].value)
            elseif views["duration_unit_" .. i].value == 2 then
                section.durations[i].value = math.floor (views["duration_" .. i].value) / 100
            else
                section.durations[i].value = math.floor (views["duration_" .. i].value / 10)
            end
            section.durations[i].scale = math.floor (views["duration_scale_" .. i].value + 0.5)
        else
            section.durations[i].value =  0
            section.durations[i].unit = MorphSynthWindow.durations_unit_names[1]
            section.durations[i].scale = 0
        end
    end

    section.waveforms = {}
    for i = 1, self.nb_waveforms do
        local w = { }
        w.operator = WaveFunctions.names[views["function_" .. i].value]
        w.shape = math.floor (views["shape_" .. i].value + 0.5)
        w.phase = math.floor (views["phase_" .. i].value + 0.5)
        w.inverted = views["inverted_" .. i].value
        if (section_index == MorphSynthWindow.section_carrier) or  (section_index == MorphSynthWindow.section_ring) then
            w.transpose = math.floor (views["transpose_" .. i].value + 0.5)
        else
            w.ratio_dividend = views["ratio_dividend_" .. i].value
            w.ratio_divisor = views["ratio_divisor_" .. i].value
        end
        w.finetune = math.floor (views["finetune_" .. i].value + 0.5)
        w.sample_and_hold = math.floor (views["sample_and_hold_" .. i].value + 0.5)
        --~ if is_modulator then
            --~ w.frequency_offset = views["frequency_offset_" .. i].value
        --~ end
        if section_index == MorphSynthWindow.section_carrier then
            w.amplitude = math.floor (views["amplitude_" .. i].value + 0.5)
        elseif section_index == MorphSynthWindow.section_ring then
            w.amount = math.floor (views["rm_amount_" .. i].value + 0.5)
        else
            local v = from_exp_display (views["fm_amount_" .. i].value, 13.1)
            w.amount = math.floor (v * 10 + 0.5) / 10
        end
        section.waveforms[i] = w
    end

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:update_gui ()

    local views = self.vb.views
    local voice = self.morph_synth.voices[views.voice.value] ---TODO

    views.volume.value = voice.volume - 1
    views.volume_rotary.value = voice.volume - 1
    views.panning.value = voice.panning
    views.panning_rotary.value = voice.panning
    views.transpose.value = voice.transpose
    views.finetune.value = voice.finetune
    views.seed.value = voice.seed
    views.seed_rotary.value = voice.seed
    views.new_note_action.value = 1
    for i = 1, #MorphSynthWindow.nna_names do
        if MorphSynthWindow.nna_names[i] == voice.new_note_action then
            views.new_note_action.value = i
        end
    end
    views.fm_algorithm.value = (voice.fm_algorithm == "Parallel") and 1 or 2
    if voice.autofade then
        views.autofade.value = 2
    else
        views.autofade.value = 1
    end
    views.envelopes.value = voice.envelopes

    while self.nb_waveforms > 1 do
        self:remove_waveform ()
        self.nb_waveforms = self.nb_waveforms - 1
        self:remove_duration ()
    end
    if self.nb_waveforms == 1 then
        self:remove_waveform ()
        self.nb_waveforms = 0
    end

    ---TODO: factorize
    if views.voice_section.value == MorphSynthWindow.section_carrier then
        if #voice.carrier.waveforms > 0 then
            self.nb_waveforms = 1
            self:add_waveform (voice.carrier.waveforms[self.nb_waveforms], views.voice_section.value)
            for i = 2, #voice.carrier.waveforms do
                self:add_duration (voice.carrier.durations[self.nb_waveforms])
                self.nb_waveforms = self.nb_waveforms + 1
                self:add_waveform (voice.carrier.waveforms[self.nb_waveforms], views.voice_section.value)
            end
        end
    elseif views.voice_section.value == MorphSynthWindow.section_fm1 then
        if #voice.frequency_modulator_1.waveforms > 0 then
            self.nb_waveforms = 1
            self:add_waveform (voice.frequency_modulator_1.waveforms[self.nb_waveforms], views.voice_section.value)
            for i = 2, #voice.frequency_modulator_1.waveforms do
                self:add_duration (voice.frequency_modulator_1.durations[self.nb_waveforms])
                self.nb_waveforms = self.nb_waveforms + 1
                self:add_waveform (voice.frequency_modulator_1.waveforms[self.nb_waveforms], views.voice_section.value)
            end
        end
    elseif views.voice_section.value == MorphSynthWindow.section_fm2 then
        if #voice.frequency_modulator_2.waveforms > 0 then
            self.nb_waveforms = 1
            self:add_waveform (voice.frequency_modulator_2.waveforms[self.nb_waveforms], views.voice_section.value)
            for i = 2, #voice.frequency_modulator_2.waveforms do
                self:add_duration (voice.frequency_modulator_2.durations[self.nb_waveforms])
                self.nb_waveforms = self.nb_waveforms + 1
                self:add_waveform (voice.frequency_modulator_2.waveforms[self.nb_waveforms], views.voice_section.value)
            end
        end
    elseif views.voice_section.value == MorphSynthWindow.section_ring then
        if #voice.ring_modulator.waveforms > 0 then
            self.nb_waveforms = 1
            self:add_waveform (voice.ring_modulator.waveforms[self.nb_waveforms], views.voice_section.value)
            for i = 2, #voice.ring_modulator.waveforms do
                self:add_duration (voice.ring_modulator.durations[self.nb_waveforms])
                self.nb_waveforms = self.nb_waveforms + 1
                self:add_waveform (voice.ring_modulator.waveforms[self.nb_waveforms], views.voice_section.value)
            end
        end
    end



    views.loop_mode.value = voice.loop_mode
    views.loop_from_label.visible = views.loop_mode.value > 1
    views.loop_from.visible = views.loop_mode.value > 1
    views.loop_from.value = voice.loop_from
    views.loop_to_label.visible = views.loop_mode.value > 2
    views.loop_to.visible = views.loop_mode.value > 2
    views.loop_to.value = voice.loop_to
    views.loop_to_end_label.visible = views.loop_mode.value == 2

end


----------------------------------------------------------------------------------------------------


local function to_note_string (v)

    local octave = math.floor (v / 12)
    local note = v % 12 + 1
    local note_names = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" }
    local note_name = note_names[note]

    return note_name .. octave

end

local note_numbers = { ["C-"] = 0, ["C#"] = 1, ["D-"] = 2, ["D#"] = 3, ["E-"] = 4, ["F-"] = 5, ["F#"] = 6, ["G-"] = 7, ["G#"] = 8, ["A-" ]= 9, ["A#"] = 10, ["B-"] = 11,
                       ["c-"] = 0, ["c#"] = 1, ["d-"] = 2, ["d#"] = 3, ["e-"] = 4, ["f-"] = 5, ["f#"] = 6, ["g-"] = 7, ["g#"] = 8, ["a-" ]= 9, ["a#"] = 10, ["b-"] = 11 }

local function to_note_number (v)

    local note_name, octave_name = string.match (v, "([a-gA-G][%-#])([0-9])")
    if not note_name or not octave_name then
        return 48
    end

    local note = note_numbers[note_name]
    if note == nil then
        note = 0
    end

    local octave = tonumber (octave_name)

    return octave * 12 + note

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:gui ()

    local vb = self.vb
    local ms = self.morph_synth

    local dialog_margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
    local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local control_margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    local control_height = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

    local sample_rate = 1
    if     ms.sample_rate == 11025 then sample_rate = 1
    elseif ms.sample_rate == 22050 then sample_rate = 2
    elseif ms.sample_rate == 32000 then sample_rate = 3
    elseif ms.sample_rate == 44100 then sample_rate = 4
    elseif ms.sample_rate == 48000 then sample_rate = 5
    elseif ms.sample_rate == 88200 then sample_rate = 6
    elseif ms.sample_rate == 96000 then sample_rate = 7
    elseif ms.sample_rate == 44000 then sample_rate = 8
    end

    local bit_depth = 1
    if     ms.bit_depth == 16 then bit_depth = 1
    elseif ms.bit_depth == 24 then bit_depth = 2
    elseif ms.bit_depth == 32 then bit_depth = 3
    end

    local section_width = 650

    local result = vb:column
    {
        style = "body",
        margin = dialog_margin,
        spacing = dialog_spacing,
        uniform = true,


        vb:horizontal_aligner
        {
            mode = "justify",
            vb:column
            {
                style = "group",
                margin = control_margin,
                spacing = control_spacing,
                width = "55%",
                height = "100%",

                vb:row
                {
                    vb:text { text = "Sample Rate", width = 80, },
                    vb:popup { id = "sample_rate", items = self.sample_rate_names, value = sample_rate, },

                    vb:text { text = "    Bit Depth", width = 80, },
                    vb:popup { id = "bit_depth", items = self.bit_depth_names, value = bit_depth, width = 40, },
                },

                vb:row
                {
                    vb:text { text = "Note Range", width = 80, },
                    vb:valuebox { id = "first_note", value = ms.first_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                    vb:valuebox { id = "last_note", value = ms.last_note, min = 0, max = 119, tostring = to_note_string, tonumber = to_note_number, },
                    vb:text { text = "    Step", width = 60, },
                    vb:valuebox { id = "keyzones_step", value = ms.keyzones_step, min = 1, max = 12, },
                },
            },

            vb:column
            {
                style = "group",
                margin = control_margin,
                spacing = control_spacing,
                width = "40%",
                height = "100%",
                vb:text { text = " " },
            },
        },


        vb:column
        {
            margin = control_margin,
            spacing = control_spacing,
            width = section_width,
            vb:text { text = "Voices", font = "bold", width = "100%", align = "center", },
            vb:switch
            {
                id = "voice",
                width = "100%", -- width = 8 * 40,
                height = 25,
                items = { "1", "2", "3", "4", "5", "6", "7", "8" },
                value = 1,
                notifier = function (index)
                    self:update_parameters (self.previous_voice, vb.views.voice_section.value)
                    self:update_gui ()
                    self.previous_voice = index
                end,
            },
        },



        vb:column
        {
            width = section_width,
            style = "group",
            margin = control_margin,
            spacing = control_spacing,


            vb:horizontal_aligner
            {
                width = "100%",
                mode = "distribute",

                vb:column
                {
                    uniform = true,
                    vb:text { text = "Volume", font = "bold", align = "center", width = 60 },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        width = 60,
                        vb:rotary
                        {
                            id = "volume_rotary",
                            min = -1,
                            max = 0,
                            value = 0,
                            notifier = function () vb.views.volume.value = vb.views.volume_rotary.value end,
                        },
                    },
                    vb:valuefield
                    {
                        id = "volume",
                        align = "center",
                        width = 60,
                        min = -1,
                        max = 0,
                        value = 0,
                        tonumber = function (v)
                            local r = math.pow (10, tonumber(v) / 20) - 1
                            if r > 0 then r = 0 end
                            if r < -1 then r = -1 end
                            return r
                        end, ---TODO
                        tostring = function (v) return string.format ("%.3g dB", 20 * math.log10 (v + 1)) end,
                        notifier = function () vb.views.volume_rotary.value = vb.views.volume.value end,
                    },
                },

                vb:column
                {
                    uniform = true,
                    vb:text { text = "Panning", font = "bold", align = "center", width = 60 },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        width = 60,
                        vb:rotary
                        {
                            id = "panning_rotary",
                            min = -50,
                            max = 50,
                            value = 0,
                            notifier = function () vb.views.panning.value = vb.views.panning_rotary.value end,
                        },
                    },
                    vb:valuefield
                    {
                        id = "panning",
                        align = "center",
                        min = -50,
                        max = 50,
                        value = 0,
                        width = 60,
                        tonumber = function (v)
                            ---TODO: handle "L" and "R" suffixes
                            local nv = tonumber(v)
                            if nv < - 50 then
                                nv = -50
                            elseif nv > 50 then
                                nv = 50
                            end
                            return nv
                        end,
                        tostring = function (v)
                            v = math.floor(v + 0.5)
                            if v == 0 then
                                return "Center"
                            elseif v > 0 then
                                return tostring(v) .. " R"
                            else
                                return tostring(-v) .. " L"
                            end
                        end,
                        notifier = function () vb.views.panning_rotary.value = vb.views.panning.value end
                    },
                },

                vb:column
                {
                    uniform = true,
                    vb:text { text = "Transpose ", font = "bold", align = "right", width = 60 },
                    vb:vertical_aligner
                    {
                        mode = "distribute",
                        vb:valuebox
                        {
                            id = "transpose",
                            min = -60,
                            max = 60,
                            value = 0,
                            width = 70,
                            tonumber = tonumber, ---TODO
                            tostring = function (v) return string.format("% 2d st", math.floor(v+0.5)) end,
                        },
                        vb:valuebox
                        {
                            id = "finetune",
                            width = 70,
                            min = -127,
                            max = 127,
                            tonumber = function (v)
                                local r = tonumber(v)
                                if r < -127 then
                                    r = -127
                                elseif r > 127 then
                                    r = 127
                                end
                                return r
                            end,
                            tostring = function (v) return string.format ("% 2d", math.floor(v + 0.5)) end,
                        },
                    },
                },

                vb:column
                {
                    uniform = true,
                    vb:text { width = 40, text = "Seed ", font = "bold", align = "right", },
                    vb:rotary
                    {
                        id = "seed_rotary",
                        width = 40,
                        height = 40,
                        min = 0,
                        max = 100,
                        notifier = function () vb.views.seed.value = vb.views.seed_rotary.value end,
                    },
                    vb:valuefield
                    {
                        id = "seed",
                        min = 0,
                        max = 100,
                        width = 40,
                        align = "center",
                        tonumber = tonumber, ---TODO
                        tostring = function (v) return string.format ("%d", math.floor (v + 0.5)) end,
                        notifier = function () vb.views.seed_rotary.value = vb.views.seed.value end,
                    },
                },

                vb:vertical_aligner
                {
                    mode = "top",
                    vb:text { width = 40, text = "FM Algorithm", font="bold", },
                    vb:vertical_aligner
                    {
                        mode = "distribute",
                        vb:chooser
                        {
                            id = "fm_algorithm",
                            width = 40,
                            items = MorphSynthWindow.fm_algorithm_names,
                            value = 1,
                            tooltip = "Controls how the signal is modulated:\nParallel: FM1->Carrier and FM2->Carrier\nSerie: FM2->FM1->Carrier",
                        },
                        vb:text { text = " " },
                    },
                },

                vb:vertical_aligner
                {
                    mode = "distribute",
                    vb:row
                    {
                        vb:text { width = 45, text = "NNA ", font = "bold", align = "right", },
                        vb:popup
                        {
                            id = "new_note_action",
                            items = MorphSynthWindow.nna_names,
                        },
                    },
                    vb:row
                    {
                        vb:text { width = 45, text = "Attack ", font = "bold", align = "right", },
                        vb:popup
                        {
                            id = "autofade",
                            items = { "Raw", "Autofade", },
                        },
                    },
                    vb:horizontal_aligner
                    {
                        mode = "center",
                        vb:checkbox
                        {
                            id = "envelopes",
                        },
                        vb:text
                        {
                            text = "envelopes",
                        },
                    },
                },

            },

        },

        vb:switch
        {
            id = "voice_section",
            width = "100%", -- width = 8 * 40,
            height = 25,
            items = MorphSynthWindow.section_names,
            value = 1,
            notifier = function (index)
                self:update_parameters (vb.views.voice.value, self.previous_section)
                self:update_gui ()
                self.previous_section = index
                vb.views.loop_buttons.visible = index == MorphSynthWindow.section_carrier
                vb.views.header_amplitude.visible = index == MorphSynthWindow.section_carrier
                vb.views.header_amount.visible = index ~= MorphSynthWindow.section_carrier
                vb.views.header_pitch.visible = (index == MorphSynthWindow.section_carrier) or (index == MorphSynthWindow.section_ring)
                vb.views.header_ratio.visible = (index == MorphSynthWindow.section_fm1) or (index == MorphSynthWindow.section_fm2)
            end,
        },


        vb:column
        {
            width = section_width,
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:horizontal_aligner
            {
                mode = "left",
                margin = 0,
                spacing = 0,
                vb:text { font = "bold", align = "left", text = " ", width = 120, },
                vb:text { font = "bold", align = "left", text = "Shape", width = 70, },
                vb:text { font = "bold", align = "left", text = "S & H", width = 70, },
                vb:text { font = "bold", align = "center", text = "Phase", width = 70, },
                vb:column { width = 10 },
                vb:text { id = "header_pitch", font = "bold", align = "center", text = "Pitch", width = 70, },
                vb:text { id = "header_ratio", visible = false, font = "bold", align = "center", text = "Ratio", width = 130, },
                vb:column { width = 10 },
                vb:text { id = "header_amplitude", font = "bold", align = "left", text = "Amplitude", width = 70, },
                vb:text { id = "header_amount", visible = false, font = "bold", align = "left", text = "Amount", width = 70, },
            },

            vb:column
            {
                id = "waveforms",
                spacing = control_spacing,

            },

            vb:row { height = 10, },

            vb:horizontal_aligner
            {
                mode = "left",
                spacing = dialog_spacing,
                vb:row { width = 20 },
                vb:button
                {
                    text = "Add New Waveform",
                    --~ width = 26,
                    height = 26,
                    notifier = function ()
                        if self.nb_waveforms > 0 then
                            self:add_duration ({value = 200, unit = "ms", scale = 0})
                        end
                        self.nb_waveforms = self.nb_waveforms + 1
                        self:add_waveform ({operator="Sine", shape=0, transpose=0, finetune=0, phase=0, inverted=false, sample_and_hold=0, amplitude=100, amount=0}, vb.views.voice_section.value)
                    end,
                },
                vb:button
                {
                    text = "Delete Last Waveform",
                    --~ width = 26,
                    height = 26,
                    notifier = function ()
                        if self.nb_waveforms == 1 then
                            if vb.views.voice_section.value == MorphSynthWindow.section_carrier then
                                self:remove_waveform ()
                                self.nb_waveforms = self.nb_waveforms - 1
                            end
                        elseif self.nb_waveforms > 1 then
                            self:remove_waveform ()
                            self.nb_waveforms = self.nb_waveforms - 1
                            self:remove_duration ()
                        end
                    end,
                },
                vb:row { height = 26, },
            },

        },


        vb:column
        {
            width = section_width,
            style = "group",
            margin = control_margin,
            spacing = control_spacing,

            vb:horizontal_aligner
            {
                id = "loop_buttons",
                width = "100%",
                mode = "left",

                vb:text { text = " ", width = 20 } ,
                vb:popup
                {
                    id = "loop_mode",
                    items = { "One Shot", "Loop", "Loop/Release" },
                    value = 1,
                    notifier = function ()
                        vb.views.loop_from_label.visible = vb.views.loop_mode.value > 1
                        vb.views.loop_from.visible = vb.views.loop_mode.value > 1
                        vb.views.loop_to_label.visible = vb.views.loop_mode.value > 2
                        vb.views.loop_to.visible = vb.views.loop_mode.value > 2
                        vb.views.loop_to_end_label.visible = vb.views.loop_mode.value == 2
                    end,
                },
                vb:text { id = "loop_from_label", text = "  From  ", visible = false },
                vb:valuebox
                {
                    id = "loop_from",
                    value = 1,
                    min = 1,
                    visible = false,
                },
                vb:text { id = "loop_to_label", text = "  To  ", visible = false },
                vb:valuebox
                {
                    id = "loop_to",
                    value = 1,
                    min = 1,
                    visible = false
                },
                vb:text { id = "loop_to_end_label", text = "  To End", visible = false }
            },

        },


        vb:horizontal_aligner
        {
            margin = control_margin,
            spacing = control_spacing,
            width = section_width,
            mode = "justify",
            height = 26,

            vb:column
            {
                style = "group",
                width = "50%",
                height = "100%",
                uniform = true,
                margin = 2,
                vb:column
                {
                    style = "plain",
                    width = "100%",
                    vb:text { id = "status", text = "MorphSynth Opened", height = 24, },
                },
            },

            vb:button
            {
                width = "50%",
                height = "100%",
                text = "Generate Samples",
                notifier = function () self:generate_samples () end
            }

        },

    }

    self.nb_waveforms = 0
    self:update_gui ()
    self.previous_voice = 1
    self.previous_section = 1

    status = vb.views.status

    return result

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:add_duration (d)

    local vb = self.vb
    local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING

    local n = self.nb_waveforms

    local dv = d.value
    if d.unit == "s" then
        dv = dv * 100
    elseif d.unit == "osc" then
        dv = dv * 10
    end

    local uv = 1
    for i = 1, #MorphSynthWindow.durations_unit_names do
        if MorphSynthWindow.durations_unit_names[i] == d.unit then
            uv = i
        end
    end

    vb.views.waveforms:add_child (vb:column
    {
        id = "duration_group_" .. n,
        vb:row { height = 10},
        vb:row
        {
            height = 25,
            vb:vertical_aligner
            {
                spacing = 0,
                margin = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "duration_" .. n,
                    align = "right",
                    width = 50,
                    min = 0, max = 1000,
                    value = dv,
                    tonumber = function (v)
                        local r
                        if vb.views["duration_unit_" .. n].value == 1 then
                            r = math.floor(tonumber(v))
                        elseif vb.views["duration_unit_" .. n].value == 2 then
                            r = math.floor(tonumber(v) * 100)
                        else
                            r = math.floor(tonumber(v)) * 10
                        end
                        if r < 0 then r = 0 end
                        if r > 1000 then r = 1000 end
                        return r
                    end,
                    tostring = function (v)
                        if vb.views["duration_unit_" .. n].value == 1 then
                            return tostring(math.floor(v))
                        elseif vb.views["duration_unit_" .. n].value == 2 then
                            return tostring(math.floor(v)/100)
                        else
                            return tostring(math.floor(v/10))
                        end
                    end,
                    notifier = function () vb.views["duration_slider_" .. n].value = vb.views["duration_" .. n].value end,
                },
            },

            vb:row { width = 10, },

            vb:vertical_aligner
            {
                spacing = 0,
                margin = 0,
                mode = "center",
                vb:switch
                {
                    id = "duration_unit_" .. n,
                    items = MorphSynthWindow.durations_unit_names,
                    value = uv,
                    notifier = function ()
                        -- Trick to refresh displayed value
                        local v = vb.views["duration_" .. n].value
                        vb.views["duration_" .. n].value = 0
                        vb.views["duration_" .. n].value = v
                    end,
                    width = 70,
                },
            },

            vb:row { width = 10, },

            vb:vertical_aligner
            {
                spacing = 0,
                margin = 0,
                mode = "center",
                vb:minislider
                {
                    id = "duration_slider_" .. n,
                    min = 0, max = 1000,
                    value = dv,
                    notifier = function () vb.views["duration_" .. n].value = vb.views["duration_slider_" .. n].value end,
                    width = 350,
                },
            },

            vb:row { width = 10, },

            vb:rotary
            {
                id = "duration_scale_rotary_" .. n,
                width = 25,
                height = 25,
                min = -100,
                max = 100,
                value = d.scale,
                notifier = function () vb.views["duration_scale_" .. n].value = vb.views["duration_scale_rotary_" .. n].value end,
            },
            vb:vertical_aligner
            {
                spacing = 0,
                margin = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "duration_scale_" .. n,
                    min = -100,
                    max = 100,
                    value = d.scale,
                    tonumber = tonumber, ---TODO
                    tostring = function (v)
                        if v == 0 then
                            return "linear"
                        elseif v > 0 then
                            return string.format ("%d %% log", math.floor(v+0.5))
                        else
                            return string.format ("%d %% exp", -math.floor(v+0.5))
                        end
                    end,
                    notifier = function () vb.views["duration_scale_rotary_" .. n].value = vb.views["duration_scale_" .. n].value end,
                },
            },
        },
        vb:row { height = 10},
    } )

end


----------------------------------------------------------------------------------------------------


function MorphSynthWindow:add_waveform (w, voice_section)

    local vb = self.vb
    local control_spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
    local dialog_spacing = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
    local rotary_width = 70

    local n = self.nb_waveforms

    local opv = 1
    for i = 1, #WaveFunctions.names do
        if WaveFunctions.names[i] == w.operator then
            opv = i
        end
    end

    vb.views.waveforms:add_child (vb:column
    {
        id = "waveform_group_" .. n,
        spacing = control_spacing,

        vb:row
        {
            margin = 0,
            spacing = 0,

            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:row
                {
                    margin = 0,
                    spacing = 0,
                    vb:text { text = "" .. n .. ".", font = "bold", width = 20 },
                    vb:popup { id = "function_" .. n, items = WaveFunctions.names, width = 80, value = opv },
                },
            },

            vb:row { margin = 0, spacing = 0, width = 20 },

            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:rotary
                {
                    id = "shape_rotary_" .. n,
                    min = -100, max = 100,
                    value = w.shape,
                    width = 30,
                    height = 30,
                    notifier = function () vb.views["shape_" .. n].value = vb.views["shape_rotary_" .. n].value end,
                },
            },
            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "shape_" .. n,
                    min = -100, max = 100,
                    value = w.shape,
                    width = 40,
                    align = "left",
                    tonumber = function (v)
                        local r = tonumber(v)
                        if r > 100 then
                            r = 100
                        elseif r < -100 then
                            r = -100
                        end
                        return r
                    end,
                    tostring = function (v) return string.format ("%d %%", math.floor (v + 0.5)) end,
                    notifier = function () vb.views["shape_rotary_" .. n].value = vb.views["shape_" .. n].value end,
                },
            },

            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:rotary
                {
                    id = "sample_and_hold_rotary_" .. n,
                    min = 0, max = 64,
                    value = w.sample_and_hold,
                    width = 30,
                    height = 30,
                    notifier = function () vb.views["sample_and_hold_" .. n].value = vb.views["sample_and_hold_rotary_" .. n].value end,
                },
            },
            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "sample_and_hold_" .. n,
                    min = 0, max = 64,
                    value = w.sample_and_hold,
                    width = 40,
                    align = "left",
                    tonumber = function (v)
                        local r = tonumber(v)
                        if r > 64 then
                            r = 64
                        elseif r < 0 then
                            r = 0
                        end
                        return r
                    end,
                    tostring = function (v) return string.format ("%d", math.floor (v + 0.5)) end,
                    notifier = function () vb.views["sample_and_hold_rotary_" .. n].value = vb.views["sample_and_hold_" .. n].value end,
                },
            },

            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "phase_" .. n,
                    min = -180, max = 180,
                    value = w.phase,
                    width = 70,
                    align = "center",
                    tonumber = tonumber, ---TODO
                    tostring = function (v) return string.format("% 4d °", math.floor (v + 0.5)) end,
                },
                vb:horizontal_aligner
                {
                    mode = "center",
                    vb:checkbox
                    {
                        id = "inverted_" .. n,
                        value = w.inverted,
                    },
                    vb:text { text = "invert" },
                },
            },

            vb:column { width = 10 },

            vb:vertical_aligner
            {
                margin = 0,
                spacing = 0,
                mode = "distribute",

                vb:valuebox
                {
                    visible = (voice_section == MorphSynthWindow.section_carrier) or (voice_section == MorphSynthWindow.section_ring),
                    id = "transpose_" .. n,
                    min = -60, max = 60,
                    value = w.transpose,
                    width = 70,
                    tonumber = tonumber, ---TODO
                    tostring = function (v) return string.format("% 2d st", math.floor (v + 0.5)) end,
                },

                vb:row
                {
                    visible = (voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2),
                    vb:valuebox
                    {
                        id = "ratio_dividend_" .. n,
                        min = 1,
                        max = 10000,
                        value = w.ratio_dividend and w.ratio_dividend or 1,
                        width = 60,
                        tonumber = tonumber,
                        tostring = function (v) return tostring(v) end,
                    },
                    vb:text { text = " / ", align = "right", width = 10, },
                    vb:valuebox
                    {
                        id = "ratio_divisor_" .. n,
                        min = 1,
                        max = 10000,
                        value = w.ratio_divisor and w.ratio_divisor or 1,
                        width = 60,
                        tonumber = tonumber,
                        tostring = function (v) return tostring(v) end,
                    },
                },

                vb:row
                {
                    vb:text
                    {
                        visible = (voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2),
                        text = "Detune ",
                    },
                    vb:valuebox
                    {
                        id = "finetune_" .. n,
                        min = -100, max = 100,
                        value = w.finetune,
                        width = 70,
                        tonumber = tonumber, ---TODO
                        tostring = function (v) return string.format("% 2d ct", math.floor (v + 0.5)) end,
                    },
                },
            },

            vb:column { width = 10 },

            vb:vertical_aligner
            {
                visible = voice_section == MorphSynthWindow.section_carrier,
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:rotary
                {
                    id = "amplitude_rotary_" .. n,
                    min = 0, max = 100,
                    value = w.amplitude,
                    width = 30,
                    height = 30,
                    notifier = function () vb.views["amplitude_" .. n].value = vb.views["amplitude_rotary_" .. n].value end,
                },
            },
            vb:vertical_aligner
            {
                visible = voice_section == MorphSynthWindow.section_carrier,
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "amplitude_" .. n,
                    min = 0, max = 100,
                    value = w.amplitude,
                    width = 40,
                    align = "left",
                    tonumber = function (v)
                        local r = tonumber(v)
                        if r > 100 then
                            r = 100
                        elseif r < 0 then
                            r = 0
                        end
                        return r
                    end,
                    tostring = function (v) return string.format ("%d %%", math.floor (v + 0.5)) end,
                    notifier = function () vb.views["amplitude_rotary_" .. n].value = vb.views["amplitude_" .. n].value end,
                },
            },

            vb:vertical_aligner
            {
                visible = (voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2),
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:rotary
                {
                    id = "fm_amount_rotary_" .. n,
                    min = 0, max = 1,
                    value = ((voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2))
                        and to_exp_display (w.amount, 13.1) or 0,
                    width = 30,
                    height = 30,
                    notifier = function () vb.views["fm_amount_" .. n].value = vb.views["fm_amount_rotary_" .. n].value end,
                },
            },
            vb:vertical_aligner
            {
                visible = (voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2),
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "fm_amount_" .. n,
                    min = 0, max = 1,
                    value = ((voice_section == MorphSynthWindow.section_fm1) or (voice_section == MorphSynthWindow.section_fm2))
                        and to_exp_display (w.amount, 13.1) or 0,
                    width = 40,
                    align = "left",
                    tonumber = function (v)
                        local r = tonumber(v)
                        if r > 13.1 then
                            r = 13.1
                        elseif r < 0 then
                            r = 0
                        end
                        r = to_exp_display (r, 13.1)
                        return r
                    end,
                    tostring = function (v)
                        v = from_exp_display (v, 13.1)
                        return string.format ("%g", math.floor (v * 10 + 0.5) / 10)
                        end,
                    notifier = function () vb.views["fm_amount_rotary_" .. n].value = vb.views["fm_amount_" .. n].value end,
                },
            },

            vb:vertical_aligner
            {
                visible = voice_section == MorphSynthWindow.section_ring,
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:rotary
                {
                    id = "rm_amount_rotary_" .. n,
                    min = 0, max = 100,
                    value = w.amount,
                    width = 30,
                    height = 30,
                    notifier = function () vb.views["rm_amount_" .. n].value = vb.views["rm_amount_rotary_" .. n].value end,
                },
            },
            vb:vertical_aligner
            {
                visible = voice_section == MorphSynthWindow.section_ring,
                margin = 0,
                spacing = 0,
                mode = "center",
                vb:valuefield
                {
                    id = "rm_amount_" .. n,
                    min = 0, max = 100,
                    value = w.amount,
                    width = 40,
                    align = "left",
                    tonumber = function (v)
                        local r = tonumber(v)
                        if r > 100 then
                            r = 100
                        elseif r < 0 then
                            r = 0
                        end
                        return r
                    end,
                    tostring = function (v) return string.format ("%d %%", math.floor (v + 0.5)) end,
                    notifier = function () vb.views["rm_amount_rotary_" .. n].value = vb.views["rm_amount_" .. n].value end,
                },
            },

            vb:column
            {
                visible = false,
                vb:row
                {
                    uniform = true,
                    margin = 0,
                    spacing = 0,
                    vb:text { text = "Offset ", font = "bold", align = "right", width = 40, },
                    vb:valuefield
                    {
                        id = "frequency_offset_" .. n,
                        min = 0,
                        max = 96000,
                        value = w.frequency_offset and w.frequency_offset or 0,
                        width = 60,
                        align = "right",
                        tonumber = tonumber,
                        tostring = function (v) return string.format ("%d Hz", v) end,
                    },
                },
            },


        },


    } )

end


function MorphSynthWindow:remove_waveform ()

        local vb = self.vb

        vb.views.waveforms:remove_child (vb.views["waveform_group_" .. self.nb_waveforms])

        vb.views["waveform_group_" .. self.nb_waveforms] = nil
        vb.views["function_" .. self.nb_waveforms] = nil
        vb.views["length_" .. self.nb_waveforms] = nil
        vb.views["length_slider_" .. self.nb_waveforms] = nil
        vb.views["sample_and_hold_" .. self.nb_waveforms] = nil
        vb.views["sample_and_hold_rotary_" .. self.nb_waveforms] = nil
        vb.views["shape_" .. self.nb_waveforms] = nil
        vb.views["shape_rotary_" .. self.nb_waveforms] = nil
        vb.views["phase_" .. self.nb_waveforms] = nil
        vb.views["inverted_" .. self.nb_waveforms] = nil
        vb.views["transpose_" .. self.nb_waveforms] = nil
        vb.views["finetune_" .. self.nb_waveforms] = nil
        vb.views["ratio_dividend_" .. self.nb_waveforms] = nil
        vb.views["ratio_divisor_" .. self.nb_waveforms] = nil
        vb.views["frequency_offset_" .. self.nb_waveforms] = nil
        vb.views["amplitude_" .. self.nb_waveforms] = nil
        vb.views["amplitude_rotary_" .. self.nb_waveforms] = nil
        vb.views["fm_amount_" .. self.nb_waveforms] = nil
        vb.views["fm_amount_rotary_" .. self.nb_waveforms] = nil
        vb.views["rm_amount_" .. self.nb_waveforms] = nil
        vb.views["rm_amount_rotary_" .. self.nb_waveforms] = nil

end


function MorphSynthWindow:remove_duration ()

        local vb = self.vb

        vb.views.waveforms:remove_child (vb.views["duration_group_" .. self.nb_waveforms])

        vb.views["duration_group_" .. self.nb_waveforms] = nil
        vb.views["duration_" .. self.nb_waveforms] = nil
        vb.views["duration_unit_" .. self.nb_waveforms] = nil
        vb.views["duration_slider_" .. self.nb_waveforms] = nil
        vb.views["duration_scale_" .. self.nb_waveforms] = nil
        vb.views["duration_scale_rotary_" .. self.nb_waveforms] = nil

end

----------------------------------------------------------------------------------------------------


