-- TODO: actually implement this later, for now ripple works fine with just name swaps on top of it for naming consistency.
Sound = function(asset_name, options, streaming) return ripple.newSound(love.audio.newSource('assets/sounds/' .. asset_name, streaming and 'stream' or 'static'), options) end
SoundTag = ripple.newTag
Effect = love.audio.setEffect
