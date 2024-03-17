local Rachim={}
local musicutil=require "musicutil"
function Rachim:new(args)
  local m=setmetatable({},{
    __index=Rachim
  })
  local args=args==nil and {} or args
  for k,v in pairs(args) do
    m[k]=v
  end
  m:init()
  return m
end

function Rachim:init()
  self.id=self.id or 1
  self.pos=0
  self.start_playing=false
  self.is_playing=false
  local default_octaves={2,1,0,-1,-3}
  local default_dur={math.random(100,500)/65,math.random(100,500)/55,math.random(100,500)/45,
  math.random(100,500)/35,math.random(100,500)/25}
  local default_wet={0.7,0.8,0.9,0.9,1.0}
  local default_db={-12,-10,0,-2,-3}
  local default_attack={0.1,1,2,3,4}
  local default_release={1,2,4,6,8}
  local params_menu={{
    id="db",
    name="db",
    min=-48,
    max=12,
    div=0.5,
    default=default_db[self.id],
    engine=true
    },{
    id="dur",
    name="dur",
    min=0.1,
    max=60,
    div=0.1,
    exp=true,
    default=default_dur[self.id]*2,
    engine=true
    },{
    id="wet",
    name="wet",
    min=0,
    max=1,
    div=0.01,
    default=default_wet[self.id],
    engine=true
    },{
    id="length",
    name="length",
    min=1,
    max=16,
    default=math.random(2,16),
    div=1
    },{
    id="octave",
    name="octave",
    min=-3,
    max=3,
    default=default_octaves[self.id],
    div=1
    },{
    id="attack",
    name="attack",
    min=0.1,
    max=30,
    div=0.1,
    default=default_attack[self.id],
    engine=true
    },{
    id="release",
    name="release",
    min=0.1,
    max=30,
    div=0.1,
    default=default_release[self.id],
    engine=true
  }}
  local pattern_melody={}
  for i=1,math.random(3,6) do
    table.insert(pattern_melody,0)
  end
  local random_notes={1,1,1,1,1,1,1,3,3,3,3,3,3,5,5,5,5,5,5,5,4,4,4,4,2,2,2,2,2,2,6,6,6,6,6,6,6,6,6,6,7,7,8}
  for i,_ in ipairs(pattern_melody) do
    pattern_melody[i]=math.random(0,100)<5 and 0 or random_notes[math.random(#random_notes)]
  end

  for i=1,16 do
    table.insert(params_menu,{
      id="note"..i,
      name="note "..i,
      min=0,
      max=8,
      div=1,
    default=pattern_melody[(i-1)%#pattern_melody+1]})
  end

  params:add_group("pattern "..self.id,#params_menu)

  for _,pram in ipairs(params_menu) do
    local formatter=pram.formatter
    if formatter==nil and pram.values~=nil then
      formatter=function(param)
        return pram.values[param:get()]..(pram.unit and (" "..pram.unit) or "")
      end
    end
    local pid=self.id..pram.id
    params:add{
      type="control",
      id=pid,
      name=pram.name,
      controlspec=controlspec.new(pram.min,pram.max,pram.exp and "exp" or "lin",pram.div,pram.default,
      pram.unit or "",pram.div/(pram.max-pram.min)),
      formatter=formatter
    }
    if pram.hide then
      params:hide(pid)
    end
    params:set_action(pid,function(x)
      if pram.engine then
        engine.set(self.id,pram.id,x)
      elseif pram.action then
        pram.action(x)
      end
    end)
  end

  -- clock timer for playing
  self.steps=params:get(self.id.."dur")*10
  clock.run(function()
    while true do
      clock.sleep(0.1)
      self.steps=self.steps+1
      if self.start_playing then
        self.steps=params:get(self.id.."dur")*10
        self.start_playing=false
        self.is_playing=true
      end
      if self.is_playing and self.steps>=params:get(self.id.."dur")*10 then
        self.pos=self.pos+1
        if self.pos>params:get(self.id.."length") then
          self.pos=1
        end
        local note_index=params:get(self.id.."note"..self.pos)
        if note_index>0 then
          local scale=musicutil.generate_scale(params:get("root_note"),params:get("scale_mode"),1)
          local note=scale[(note_index-1)%#scale+1]+12*params:get(self.id.."octave")
          local freq=musicutil.note_num_to_freq(note)
          engine.set(self.id,"db",params:get(self.id.."db"))
          engine.set(self.id,"gate",1)
          engine.set(self.id,"freq",freq)
        else
          engine.set(self.id,"gate",0)
        end
        self.steps=0
      end
      if self.pos>params:get(self.id.."length") then
        self.pos=1
      end
    end
  end)
end

function Rachim:get_playing()
  return self.is_playing or self.start_playing
end

function Rachim:toggle()
  if self.is_playing then
    self:stop()
  else
    self:start()
  end
end

function Rachim:start()
  if not self.is_playing then
    self.start_playing=true
  end
end

function Rachim:stop()
  if self.is_playing then
    self.is_playing=false
    self.pos=0
    self.steps=10000
    engine.set(self.id,"gate",0)
  end
end

function Rachim:linlin_tohex(val,min,max)
  return string.format("%02x",util.linlin(min,max,0,255,val))
end

function Rachim:redraw()
  local y_start=12
  if params:get("sel_pattern")==self.id then
    for i=1,5 do
      if i==1 then
        if params:get("sel_param")>4 then
          local level=6
          screen.level(level)
          screen.rect(2-1,y_start+(i-1)*11-6,10,7)
          screen.fill()
          s=string.format("%02X",self.id)
          screen.level(0)
          screen.move(2,y_start+(i-1)*11)
          screen.text(s:sub(1,1))
          screen.move(2+5,y_start+(i-1)*11)
          screen.text(s:sub(-1))
        end
      else
        local param_list={"none","length","db","dur","wet"}
        local param_name={"none","len","db","dur","rev"}

        local s=string.format("%02X",util.round(
        util.linlin(0.0,1.0,0,255,params:get_raw(self.id..param_list[i]))))
        if i==2 then
          s=string.format("%02X",params:get(self.id..param_list[i]))
        end
        local level=6
        screen.level(level)
        if i==params:get("sel_param")+1 and self.id==params:get("sel_pattern") then
          screen.rect(2-1,y_start+(1-1)*11-6,10,7)
          screen.fill()
          screen.level(0)
          screen.move(2+4,y_start+(1-1)*11)
          local s1=param_name[i]
          -- truncate to 3 characters
          if string.len(s1)>3 then
            s1=string.sub(s1,1,3)
          end
          screen.text_center(s1)

          screen.level(level)
          screen.rect(2-1,y_start+(i-1)*11-6,10,7)
          screen.fill()
          screen.level(0)

        end

        screen.move(2,y_start+(i-1)*11)
        screen.text(s:sub(1,1))
        screen.move(2+5,y_start+(i-1)*11)
        screen.text(s:sub(-1))

      end
    end
  end
  for j=1,params:get(self.id.."length") do
    local level=2
    if self.id==params:get("sel_pattern") then
      level=7
    end
    if j==self.pos and self.is_playing then
      level=15
    end
    screen.level(level)
    if j==params:get("sel_param")-4 and self.id==params:get("sel_pattern") then
      screen.rect(3+2+14+(j-1)*6-1,y_start+(self.id-1)*11-6,5,7)
      screen.fill()
      screen.level(0)
    end
    screen.move(3+2+14+(j-1)*6,y_start+(self.id-1)*11)
    screen.text(params:get(self.id.."note"..j))
  end

  s=string.format("%02X",util.round(util.linlin(0,params:get(self.id.."dur")*10,0,255,self.steps)))
  screen.level(2)
  screen.move(128-9,y_start+(self.id-1)*11)
  screen.text(s:sub(1,1))
  screen.move(128-9+5,y_start+(self.id-1)*11)
  screen.text(s:sub(-1))

end

return Rachim
