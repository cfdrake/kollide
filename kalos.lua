-- kalos: k-loop clone
-- by: @cfd90
--
-- K2 play sample 1
-- K3 play sample 2
-- E1 rate
-- E2 lfo rate
-- E3 lfo amount

-- TODO:
-- K1 + K2 and K1 + K3 to load sample 3 and sample 4
-- get psets working
-- maybe increase size of LFO in rate animation

local rate = 1
local lfo_rate = 0.05
local lfo_val = 0
local lfo_amount = 0
local c = 0

local sample = -1
local file1 = ""
local file2 = ""

function init()
  params:add_separator()
  
  params:add_file("sample 1", "sample 1")
  params:set_action("sample 1", function(file)
    local was_empty = file1 == "" and file2 == ""
    file1 = file
    if was_empty then
      load_file(1)
    end
  end)
  
  params:add_file("sample 2", "sample 2")
  params:set_action("sample 2", function(file)
    local was_empty = file1 == "" and file2 == ""
    file2 = file
    if was_empty then
      load_file(2)
    end
  end)

  softcut.buffer_clear()
  softcut.enable(1, 1)
  softcut.buffer(1, 1)
  softcut.level(1, 1)
  softcut.loop(1, 1)
  softcut.loop_start(1, 1)
  softcut.loop_end(1, 1)
  softcut.position(1, 1)
  softcut.rate(1, 1)
  softcut.play(1, 1)
  
  lfo_metro = metro.init()
  lfo_metro.time = .01
  lfo_metro.event = function()
    lfo()
  end
  
  ui_metro = metro.init()
  ui_metro.time = 1/30
  ui_metro.event = function()
    redraw()
  end
  
  ui_metro:start()
  lfo_metro:start()
end

function load_file(n)
  file = ""
  sample = n
  
  if n == 1 then
    file = file1
  else
    file = file2
  end
    
  -- softcut.play(1, 0)
  softcut.buffer_clear()
  softcut.buffer_read_mono(file, 0, 1, -1, 1, 1)
  softcut.enable(1, 1)
  softcut.buffer(1, 1)
  softcut.level(1, 1)
  softcut.loop(1, 1)
  softcut.loop_start(1, 1)
  softcut.loop_end(1, file_length(file))
  softcut.position(1, 1)
  -- softcut.rate(1, 1)
  softcut.play(1, 1)
end 

function lfo()
  c = c + lfo_rate
  lfo_val = lfo_amount * math.sin(c)
  softcut.rate(1, rate + lfo_val)
end

function enc(n, d)
  if n == 1 then
    rate = util.clamp(rate + d / 100, -3, 3)
    softcut.rate(1, rate)
  elseif n == 2 then
    lfo_rate = util.clamp(lfo_rate + d / 500, 0.01, 0.5)
  elseif n == 3 then
    lfo_amount = util.clamp(lfo_amount + d / 500, 0, 1)
  end
  
  redraw()
end

function key(n, z)
  if n >= 2 and n <= 3 and z == 1 then
    load_file(n - 1)
  end
end

function redraw()
  screen.clear()
  
  local radius = 3 + math.abs((rate * 8) + (lfo_val * 2))
  screen.level(1)
  screen.move(64 + radius, 32)
  screen.circle(64, 32, radius)
  screen.stroke()
  
  if file1 == "" and file2 == "" then
    screen.level(5)
    screen.move(0, 10)
    screen.text("^ load a file to start...")
  end
  
  screen.level(15)
  screen.move(0, 40)
  screen.text("pitch > ")
  screen.level(3)
  screen.text(string.format("%.2f", rate))
  screen.move(0, 50)
  screen.level(15)
  screen.text("lfo speed > ")
  screen.level(3)
  screen.text(string.format("%.2f", lfo_rate))
  screen.move(0, 60)
  screen.level(15)
  screen.text("lfo amnt > ")
  screen.level(3)
  screen.text(string.format("%.2f", lfo_amount))
  
  if sample ~= -1 then
    screen.move(91, 60)
    screen.level(15)
    screen.text("samp > ")
    screen.level(3)
    screen.text(sample)
  end
  
  screen.update()
end

function file_length(file)
  if util.file_exists(file) == true then
    local ch, samples, samplerate = audio.file_info(file)
    local duration = samples / samplerate
    
    return duration
  else
    return 0
  end
end
