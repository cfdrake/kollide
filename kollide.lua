-- kollide: k-loop-alike
-- by: @cfd90
--
-- K2 play sample 1
-- K3 play sample 2
-- E1 pitch
-- E2 lfo speed
-- E3 lfo amount
--
-- thanks: critter and guitari

-- Variables for calculating LFO.
local lfo_val = 0
local lfo_counter = 0

-- Quantization.
local intervals = {
  -4,
  -3,
  -2,
  -1.5,
  -1,
  -0.5,
  -0.25,
  0,
  0.25,
  0.5,
  1,
  1.5,
  2,
  3,
  4
}

function init()
  -- Initialize softcut.
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
  
  -- Set up params.
  params:add_separator()
  params:add_file("sample 1", "sample 1")
  params:set_action("sample 1", function(filename)
    load_file(filename)
  end)
  
  params:add_file("sample 2", "sample 2")
  params:set_action("sample 2", function(filename)
    load_file(filename)
  end)
  
  params:add{id="rate", name="pitch", type="control", controlspec=controlspec.new(-4.0, 4.0, 'lin', 0.01, 1, "", 1/500)}
  params:add_option("quantize", "quantize?", {"yes", "no"}, 2)
  params:add{id="lfo_rate", name="lfo speed", type="control", controlspec=controlspec.new(0.01, 0.5, 'lin', 0.01, 0.05, "", 1/500)}
  params:add{id="lfo_amount", name="lfo amount", type="control", controlspec=controlspec.new(0, 1, 'lin', 0.01, 0, "", 1/500)}

  -- Set up LFO timer.
  lfo_metro = metro.init()
  lfo_metro.time = .01
  lfo_metro.event = function()
    update_lfo()
  end
  
  lfo_metro:start()
  
  -- Set up UI timer.
  ui_metro = metro.init()
  ui_metro.time = 1/30
  ui_metro.event = function()
    redraw()
  end
  
  ui_metro:start()
end

function load_file(filename)
  softcut.buffer_clear()
  softcut.buffer_read_mono(filename, 0, 1, -1, 1, 1)
  softcut.enable(1, 1)
  softcut.buffer(1, 1)
  softcut.level(1, 1)
  softcut.loop(1, 1)
  softcut.loop_start(1, 1)
  softcut.loop_end(1, file_length(filename))
  softcut.position(1, 1)
  softcut.play(1, 1)
end 

function update_lfo()
  -- Increase counter. Taking sin() from this smooths out rate changes.
  lfo_counter = lfo_counter + params:get("lfo_rate")
  lfo_val = params:get("lfo_amount") * math.sin(lfo_counter)
  
  -- Set softcut rate.
  local r = params:get("rate")
  local should_quantize = params:get("quantize") == 1

  if should_quantize then
    r = quantize(r, intervals)
  end

  softcut.rate(1, r + lfo_val)
end

function enc(n, d)
  if n == 1 then
    params:delta("rate", d)
  elseif n == 2 then
    params:delta("lfo_rate", d)
  elseif n == 3 then
    params:delta("lfo_amount", d)
  end
end

k1_held = false

function key(n, z)
  if n == 2 and z == 1 then
    load_file(params:get("sample 1"))
  elseif n == 3 and z == 1 then
    load_file(params:get("sample 2"))
  end
end

function redraw()
  screen.clear()
  
  -- Draw animation.
  local radius = 3 + math.abs((params:get("rate") * 8) + (lfo_val * 2))
  
  screen.level(1)
  screen.move(64 + radius, 32)
  screen.circle(64, 32, radius)
  screen.stroke()
  
  -- Draw help, if needed.
  if params:get("sample 1") == "-" and params:get("sample 2") == "-" then
    screen.level(5)
    screen.move(0, 10)
    screen.text("^ load a file to start...")
  end
  
  -- Draw params.
  local r = params:get("rate")
  local should_quantize = params:get("quantize") == 1

  if should_quantize then
    r = quantize(r, intervals)
  end

  screen.level(15)
  screen.move(0, 40)
  screen.text("pitch > ")
  screen.level(3)
  screen.text(string.format("%.2f", r))
  screen.move(0, 50)
  screen.level(15)
  screen.text("lfo speed > ")
  screen.level(3)
  screen.text(string.format("%.2f", params:get("lfo_rate")))
  screen.move(0, 60)
  screen.level(15)
  screen.text("lfo amnt > ")
  screen.level(3)
  screen.text(string.format("%.2f", params:get("lfo_amount")))
  
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

function quantize(n, values)
  local best = 0
  local best_diff = 9999
  for i=1,#values do
    local v = values[i]
    local diff = math.abs(v - n)
    if diff < best_diff then
      best = v
      best_diff = diff
    end
  end
  return best
end
