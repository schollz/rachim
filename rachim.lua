-- rachim v0.1.0
--
--
-- llllllll.co/t/rachim
--
--
--
--    ▼ instructions below ▼
--
-- E1: select pattern
-- E2: select parameter
-- E3: change parameter
-- K3: toggle play
-- K1+K3: toggle play all
-- top left going down:
-- pattern id
-- length
-- volume
-- duration
-- wet
--
rachim_ = include("lib/rachim")
rachim = {}
rachim_num = 5
shift = false

installer_ = include("lib/scinstaller/scinstaller")
installer = installer_:new{
    requirements = {"Fverb", "AnalogTape", "AnalogChew", "AnalogLoss", "AnalogDegrade"},
    zip = "https://github.com/schollz/portedplugins/releases/download/v0.4.5/PortedPlugins-RaspberryPi.zip"
}
engine.name = installer:ready() and 'Rachim' or nil

function init()
    if not installer:ready() then
        clock.run(function()
            while true do
                redraw()
                clock.sleep(1 / 10)
            end
        end)
        do
            return
        end
    end

    params:add_number("sel_pattern", "pattern", 1, rachim_num, 3)
    params:add_number("sel_param", "param", 1, 20, 1)

    for i = 1, rachim_num do
        rachim[i] = rachim_:new({
            id = i
        })
    end

    params:default()
    params:set("sel_param", 5)

    for i = 1, rachim_num do
        engine.set(i, "db", -96)
    end

    clock.run(function()
        while true do
            clock.sleep(1 / 10)
            redraw()

        end
    end)
end

function key(k, z)
    if not installer:ready() then
        installer:key(k, z)
        do
            return
        end
    end
    if k == 3 and z == 1 then
        if shift then
            local is_playing = false
            for i = 1, rachim_num do
                if rachim[i]:get_playing() then
                    is_playing = true
                end
            end
            if is_playing then
                for i = 1, rachim_num do
                    rachim[i]:stop()
                end
            else
                for i = 1, rachim_num do
                    rachim[i]:start()
                end
            end
        else
            -- toggle playing
            rachim[params:get("sel_pattern")]:toggle()
        end
    elseif k == 1 then
        shift = z == 1
    end
end

function enc(k, z)
    if not installer:ready() then
        do
            return
        end
    end
    if k == 1 then
        params:delta("sel_pattern", z)
    elseif k == 2 then
        if z > 0 then
            params:delta("sel_param", 1)
        else
            params:delta("sel_param", -1)
        end
        if params:get("sel_param") > params:get(params:get("sel_pattern") .. "length") + 4 then
            params:set("sel_param", params:get(params:get("sel_pattern") .. "length") + 4)
        end
    elseif k == 3 then
        if params:get("sel_param") == 1 then
            params:delta(params:get("sel_pattern") .. "length", z)
        elseif params:get("sel_param") == 2 then
            params:delta(params:get("sel_pattern") .. "db", z)
        elseif params:get("sel_param") == 3 then
            params:delta(params:get("sel_pattern") .. "dur", z)
        elseif params:get("sel_param") == 4 then
            params:delta(params:get("sel_pattern") .. "wet", z)
        else
            params:delta(params:get("sel_pattern") .. "note" .. params:get("sel_param") - 4, z)
        end
    end
end

function redraw()
    if not installer:ready() then
        installer:redraw()
        do
            return
        end
    end
    screen.clear()
    screen.aa(0)
    screen.font_face(68)
    screen.level(15)

    for i = 1, rachim_num do
        rachim[i]:redraw()
    end
    screen.update()
end
