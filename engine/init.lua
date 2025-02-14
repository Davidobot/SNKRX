local path = ...
if not path:find("init") then
  require(path .. ".datastructures.string")
  require(path .. ".datastructures.table")
  require(path .. ".external")
  require(path .. ".graphics.graphics")
  require(path .. ".game.object")
  require(path .. ".system")
  require(path .. ".datastructures.graph")
  require(path .. ".datastructures.grid")
  require(path .. ".game.gameobject")
  require(path .. ".game.group")
  require(path .. ".game.state")
  require(path .. ".game.physics")
  require(path .. ".game.steering")
  require(path .. ".graphics.animation")
  require(path .. ".graphics.camera")
  require(path .. ".graphics.canvas")
  require(path .. ".graphics.color")
  require(path .. ".graphics.font")
  require(path .. ".graphics.image")
  require(path .. ".graphics.shader")
  require(path .. ".graphics.text")
  require(path .. ".graphics.tileset")
  require(path .. ".map.solid")
  require(path .. ".map.tilemap")
  require(path .. ".math.polygon")
  require(path .. ".math.chain")
  require(path .. ".math.circle")
  require(path .. ".math.line")
  require(path .. ".math.math")
  require(path .. ".math.random")
  require(path .. ".math.rectangle")
  require(path .. ".math.spring")
  require(path .. ".math.triangle")
  require(path .. ".math.vector")
  require(path .. ".game.trigger")
  require(path .. ".game.input")
  require(path .. ".sound")
  require(path .. ".game.parent")
  require(path .. ".game.springs")
  require(path .. ".game.flashes")
  require(path .. ".game.hitfx")
end

function resize_w_safe_area()
  if state.ignore_safe_area then
    safe_area_x, safe_area_y, safe_area_w, safe_area_h = 0, 0, ww, wh
  else
    safe_area_x, safe_area_y, real_safe_area_w, real_safe_area_h = love.window.getSafeArea()
    safe_area_w = real_safe_area_w
    safe_area_h = real_safe_area_h
    --safe_area_w = ww - safe_area_x
    --safe_area_h = wh - safe_area_y
  end

  real_safe_area_w = safe_area_w
  real_safe_area_h = safe_area_h
  real_safe_area_x = safe_area_x
  if safe_area_w * (9 / 16) > safe_area_h then
    safe_area_w = real_safe_area_h * (16 / 9)
    safe_area_x = safe_area_x + math.floor((real_safe_area_w - safe_area_w) / 2)
  else
    safe_area_h = real_safe_area_w * (9 / 16)
    safe_area_y = safe_area_y + math.floor((real_safe_area_h - safe_area_h) / 2)
  end
  sx, sy = safe_area_w/gw, safe_area_h/gh
  real_sx, real_sy = real_safe_area_w/gw, real_safe_area_h/gh
  system.save_state()
end

function engine_run(config)
  if not web then
    love.filesystem.setIdentity(config.game_name)
    system.load_state()

    local _, _, flags = love.window.getMode()
    local window_width, window_height = love.window.getDesktopDimensions(flags.display)
    if config.window_width ~= 'max' then window_width = config.window_width end
    if config.window_height ~= 'max' then window_height = config.window_height end

    local limits = love.graphics.getSystemLimits()
    local anisotropy = limits.anisotropy
    msaa = limits.canvasmsaa
    if config.msaa ~= 'max' then msaa = config.msaa end
    if config.anisotropy ~= 'max' then anisotropy = config.anisotropy end

    local is_ios = love.system.getOS() == "iOS"
    love.window.setMode(window_width, window_height, {fullscreen = config.fullscreen, vsync = config.vsync, msaa = 0, highdpi = is_ios, usedpiscale = is_ios})

    if not state then
      state = {}
      system.save_state()
    end

    if state.mouse_control == true then
      state.mouse_control = 'point' -- backwards compat
    end

    if not state.ignore_safe_area then
      state.ignore_safe_area = false
    end

    if state.ignore_safe_area then
      safe_area_x, safe_area_y, safe_area_w, safe_area_h = 0, 0, window_width, window_height
    else
      safe_area_x, safe_area_y, real_safe_area_w, real_safe_area_h = love.window.getSafeArea()

      -- a bit hacky but starts weird otherwise
      if window_height > real_safe_area_h then
        safe_area_w = window_width - safe_area_x
        safe_area_h = window_height - safe_area_y
      else
        safe_area_w = real_safe_area_w
        safe_area_h = real_safe_area_h
      end
    end

    real_safe_area_w = safe_area_w
    real_safe_area_h = safe_area_h
    real_safe_area_x = safe_area_x
    if safe_area_w * (9 / 16) > safe_area_h then
      safe_area_w = real_safe_area_h * (16 / 9)
      safe_area_x = safe_area_x + math.floor((real_safe_area_w - safe_area_w) / 2)
    else
      safe_area_h = real_safe_area_w * (9 / 16)
      safe_area_y = safe_area_y + math.floor((real_safe_area_h - safe_area_h) / 2)
    end

    gw, gh = config.game_width or 480, config.game_height or 270
    -- sx, sy = window_width/(config.game_width or 480), window_height/(config.game_height or 270)
    sx, sy = safe_area_w/gw, safe_area_h/gh

    real_sx, real_sy = real_safe_area_w/gw, real_safe_area_h/gh
    ww, wh = window_width, window_height

    state.sx, state.sy = sx, sy
    state.fullscreen = config.fullscreen

  else
    gw, gh = config.game_width or 480, config.game_height or 270 
    sx, sy = 2, 2
    ww, wh = 960, 540
  end

  --love.window.setIcon(love.image.newImageData('assets/images/icon.png'))
  love.graphics.setBackgroundColor(0, 0, 0, 1)
  love.graphics.setColor(1, 1, 1, 1)
  love.joystick.loadGamepadMappings("engine/gamecontrollerdb.txt")
  graphics.set_line_style(config.line_style or "rough")
  graphics.set_default_filter(config.default_filter or "nearest", config.default_filter or "nearest", anisotropy or 0)

  combine = Shader("default.vert", "combine.frag")
  replace = Shader("default.vert", "replace.frag")
  full_combine = Shader("default.vert", "full_combine.frag")

  input = Input()
  input:bind_all()
  for k, v in pairs(config.input or {}) do input:bind(k, v) end
  random = Random()
  trigger = Trigger()
  camera = Camera(gw/2, gh/2)
  mouse = Vector(0, 0)
  last_mouse = Vector(0, 0)
  mouse_dt = Vector(0, 0)
  init()

  if love.timer then love.timer.step() end

  if not web then
    _, _, flags = love.window.getMode()
    fixed_dt = 1/flags.refreshrate
  else fixed_dt = 1/60 end

  local accumulator = fixed_dt
  local dt = 0
  frame, time = 0, 0

  if not web then refresh_rate = flags.refreshrate
  else refresh_rate = 60 end

  return function()
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            system.save_state()
            return a or 0
          end
        elseif name == "focus" then
          --[[]
          if main.current:is(Arena) then
            if not a then open_options(main.current)
            else close_options(main.current) end
          end
          ]]--
        elseif name == "keypressed" then input.keyboard_state[a] = true; input.last_key_pressed = a
        elseif name == "keyreleased" then input.keyboard_state[a] = false
        elseif name == "mousepressed" then input.mouse_state[input.mouse_buttons[c]] = true; input.last_key_pressed = input.mouse_buttons[c]
        elseif name == "mousereleased" then input.mouse_state[input.mouse_buttons[c]] = false
        elseif name == "wheelmoved" then if b == 1 then input.mouse_state.wheel_up = true elseif b == -1 then input.mouse_state.wheel_down = true end
        elseif name == "gamepadpressed" then input.gamepad_state[input.index_to_gamepad_button[b]] = true; input.last_key_pressed = input.index_to_gamepad_button[b]
        elseif name == "gamepadreleased" then input.gamepad_state[input.index_to_gamepad_button[b]] = false
        elseif name == "gamepadaxis" then input.gamepad_axis[input.index_to_gamepad_axis[b]] = c
        elseif name == "touchpressed" then
          input.touch_state[a] = b - safe_area_x < safe_area_w / 2 and "touch_left" or "touch_right"
          if not input.finger_joystick.id then input.finger_joystick.id = a; input.finger_joystick.pos = {x = b, y = c} end
        elseif name == "touchreleased" then
          input.touch_state[a] = nil
          if input.finger_joystick.id == a then input.finger_joystick.id = nil; input.finger_joystick.pos = nil end
        elseif name == "textinput" then input:textinput(a)
        elseif name == "focus" or name == "resize" then love.handlers[name](a,b,c,d,e,f) end
      end
    end

    if love.timer then dt = love.timer.step() end

    accumulator = accumulator + dt
    while accumulator >= fixed_dt do
      frame = frame + 1
      input:update(fixed_dt)
      trigger:update(fixed_dt)
      camera:update(fixed_dt)
      local mx, my = love.mouse.getPosition()
      mx = mx - safe_area_x
      my = my - safe_area_y
      mouse:set(mx/sx, my/sy)
      mouse_dt:set(mouse.x - last_mouse.x, mouse.y - last_mouse.y)
      update(fixed_dt)
      system.update()
      input.last_key_pressed = nil
      last_mouse:set(mouse.x, mouse.y)
      accumulator = accumulator - fixed_dt
      time = time + fixed_dt
    end

    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())
      draw()
      love.graphics.present()
    end

    if love.timer then love.timer.sleep(0.001) end
  end
end
