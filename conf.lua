function love.conf(t)
  t.version = "11.3"
  t.window.width = 960
  t.window.height = 540
  t.window.vsync = 1
  t.window.msaa = 0

  -- Mobile
  t.window.usedpiscale = false
  t.window.resizable = true
  t.externalstorage = true
  t.audio.mixwithsystem = true
end
