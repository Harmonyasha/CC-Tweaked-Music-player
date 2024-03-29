local expect = require "cc.expect".expect
local char, byte, floor, band, rshift = string.char, string.byte, math.floor, bit32.band, bit32.arshift
local fixer = 0
local PREC = 10
local PREC_POW = 2 ^ PREC
local PREC_POW_HALF = 2 ^ (PREC - 1)
local STRENGTH_MIN = 2 ^ (PREC - 8 + 1)

local function make_predictor()
    local charge, strength, previous_bit = 0, 0, false

    return function(current_bit)
        local target = current_bit and 127 or -128

        local next_charge = charge + floor((strength * (target - charge) + PREC_POW_HALF) / PREC_POW)
        if next_charge == charge and next_charge ~= target then
            next_charge = next_charge + (current_bit and 1 or -1)
        end

        local z = current_bit == previous_bit and PREC_POW - 1 or 0
        local next_strength = strength
        if fixer > 100000 then
        sleep()
        fixer = 0
        end
        if next_strength ~= z then fixer = fixer+1 next_strength = next_strength + (current_bit == previous_bit and 1 or -1) end
        if next_strength < STRENGTH_MIN then next_strength = STRENGTH_MIN end

        charge, strength, previous_bit = next_charge, next_strength, current_bit
        return charge
    end
end

local function make_encoder()
    local predictor = make_predictor()
    local previous_charge = 0

    return function(input)
        expect(1, input, "table")

        local output, output_n = {}, 0
        
        for i = 1, #input, 8 do
             local this_byte = 0
            for j = 0, 7 do
                local inp_charge = floor(input[i + j] or 0)
                if inp_charge > 127 or inp_charge < -128 then
                    error(("Amplitude at position %d was %d, but should be between -128 and 127"):format(i + j, inp_charge), 2)
                end

                local current_bit = inp_charge > previous_charge or (inp_charge == previous_charge and inp_charge == 127)
                this_byte = floor(this_byte / 2) + (current_bit and 128 or 0)

                previous_charge = predictor(current_bit)
            end

            output_n = output_n + 1
            output[output_n] = char(this_byte)
        end

        return table.concat(output, "", 1, output_n)
    end
end

local function make_decoder()
    local predictor = make_predictor()
    local low_pass_charge = 0
    local previous_charge, previous_bit = 0, false

    return function (input)
        expect(1, input, "string")

        local output, output_n = {}, 0
        for i = 1, #input do
            local input_byte = byte(input, i)
            for _ = 1, 8 do
                local current_bit = band(input_byte, 1) ~= 0
                local charge = predictor(current_bit)

                local antijerk = charge
                if current_bit ~= previous_bit then
                    antijerk = floor((charge + previous_charge + 1) / 2)
                end

                previous_charge, previous_bit = charge, current_bit

                low_pass_charge = low_pass_charge + floor(((antijerk - low_pass_charge) * 140 + 0x80) / 256)

                output_n = output_n + 1
                output[output_n] = low_pass_charge

                input_byte = rshift(input_byte, 1)
            end
        end

        return output
    end
end


local function decode(input)
    expect(1, input, "string")
    return make_decoder()(input)
end


local function encode(input)
    expect(1, input, "table")
    return make_encoder()(input)
end


local speaker = peripheral.find("speaker")

local url = "Your vps or github raw idk"
local audio = url.."audio/".."bw2" -- remove if you dont use your server

audio= http.post(audio,"")

local decoder = make_decoder()
local lines = audio.readAll()

function reverse(tab)
for i = 1, #tab / 2, 1 do
tab[i], tab[#tab - i + 1] = tab[#tab - i + 1], tab[i]
end
return tab
end

print("___",#lines,"___")

local sector = decoder(lines)
local tempids = {}

local count = 1
tempids[count] = {}
 
for i,v in pairs(sector) do
    if #tempids[count] >= 100000 then
        print(count,"/",#sector/100000)
        count=count+1
        tempids[count] = {}
        sleep()
    end
    
    table.insert(tempids[count],v)
end

 

for i,v in pairs(tempids) do
      print(i,#v)
      while not speaker.playAudio(v) do
          os.pullEvent("speaker_audio_empty")
      end
      sleep()
end
