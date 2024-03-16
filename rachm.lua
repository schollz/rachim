-- rachm v0.0.0
-- 
--
-- llllllll.co/t/rachm
--
--
--
--    ▼ instructions below ▼
--
-- E1: select pattern
-- E2: select note
-- E3: change note
-- K3: play pattern
-- 
MusicUtil = require "musicutil"

pattern_selected = 1
step_selected = 1
patterns = {}
for i = 1, 5 do
    patterns[i] = {length = 16, data = {}, pos = 1, playing = False}
    for j = 1, 16 do patterns[i].data[j] = 0 end
end

function add_pattern_params()
    params:add_separator("pattern data")
    for i = 1, 5 do
        params:add_group("pattern " .. i, 19)
        params:add{
            type = "control",
            name = "pattern " .. i .. " db",
            id = "pattern_" .. i .. "_db",
            controlspec = controlspec.new(-96, 6, 'lin', 0.1, 0, 'dB')
        }
        params:add{
            type = "control",
            name = "pattern " .. i .. " duration",
            id = "pattern_" .. i .. "_dur",
            controlspec = controlspec.new(0.1, 30, 'lin', 0,
                                          math.random(1000, 20000) / 1000, 's')
        }
        params:add{
            type = "number",
            id = "pattern_" .. i .. "_length",
            name = "pattern " .. i .. " length",
            min = 1,
            max = 16,
            default = patterns[i].length,
            action = function(x) patterns[i].length = x end
        }
        for j = 1, 16 do
            params:add{
                type = "number",
                id = "pattern_" .. i .. "_data_" .. j,
                name = "pattern " .. i .. " data " .. j,
                min = 0,
                max = 8,
                default = patterns[i].data[j],
                action = function(x) patterns[i].data[j] = x end
            }
        end
    end

end

function init()
    add_pattern_params()
    params:default()

    clock.run(function()
        while true do
            clock.sleep(1 / 10)
            redraw()

        end
    end)
    for i = 1, 5 do
        -- sleep for specified pattern dur
        clock.run(function()
            while true do
                clock.sleep(params:get("pattern_" .. i .. "_dur"))
                if patterns[i].playing then
                    patterns[i].pos = patterns[i].pos % patterns[i].length + 1
                end
            end
        end)
    end
end

function key(k, z)
    if k == 3 and z == 1 then
        -- toggle playing
        patterns[pattern_selected].playing =
            not patterns[pattern_selected].playing
    end
end
function enc(k, z)
    if k == 1 then
        pattern_selected = util.wrap(pattern_selected + z, 1, 5)
        step_selected = step_selected % patterns[pattern_selected].length
    elseif k == 2 then
        step_selected = util.wrap(step_selected + z, 1,
                                  patterns[pattern_selected].length)
    elseif k == 3 then
        params:delta(
            "pattern_" .. pattern_selected .. "_data_" .. step_selected, z)
    end
end

function refresh() redraw() end

function redraw()
    screen.clear()
    screen.level(5)
    screen.rect(3, 2, 8, 7)
    screen.fill()
    screen.move(7, 8)
    screen.level(0)
    screen.text_center(pattern_selected)

    screen.level(5)
    screen.move(7, 20)
    local db = util.round(params:get("pattern_" .. pattern_selected .. "_db"))
    local db_string = db .. ""
    if db > 0 then db_string = "+" + db_string end
    screen.text_center(db_string)

    screen.move(7, 30)
    screen.text_center(util.round(params:get(
                                      "pattern_" .. pattern_selected .. "_dur"),
                                  0.1))

    for i = 1, 5 do
        for j = 1, patterns[i].length do
            local y = 12 * i - patterns[i].data[j]
            local x = 7 * j + 11
            -- center x based on the length of pattern
            x = x + (16 - patterns[i].length) / 2 * 7
            local level = 2
            if pattern_selected == i then
                level = 6
                if step_selected == j then level = 8 end
            end
            if patterns[i].playing then
                if j == patterns[i].pos then level = level + 7 end
            end

            screen.move(x, y)
            screen.line(x + 5, y)
            screen.level(level)
            screen.stroke()
        end
    end

    screen.update()
end
