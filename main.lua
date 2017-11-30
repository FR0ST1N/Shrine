player = {
  sx = 0.4,
  sy = 0.4,
  img = love.graphics.newImage("Assets/Images/playerDefault.png"),
  atk_img = love.graphics.newImage("Assets/Images/playerAttack.png"),
  y_velocity = 0,
  jump_height = -300,
  double_jump = 0,
  jump_timer = 0,
  gravity = -500,
  speed = 200,
  heat = 0,
  heatp = 1,
  direction = 1,
  state = 0,
  anim_timer = 0.2,
  score = 0,
  high_score = 0,
  alive = 0,
  toggle_control = 0
}
bullets = {
  sx = 0.1,
  sy = 0.1,
  img = love.graphics.newImage("Assets/Images/bullet.png")
}
enemies = {
  sx = 0.15,
  sy = 0.15,
  img = love.graphics.newImage("Assets/Images/enemy.png"),
  current_time = 0,
  spawn_time = 3
}

function love.load()
  love.window.setMode(1280, 720, {resizable=false}) -- Window
  love.window.setTitle("Shrine") -- Set Game Title
  -- Set Window Icon
  icon = love.graphics.newImage("Assets/Images/icon32.png");
  success = love.window.setIcon( icon:getData() );
  -- Audio Files
  bgm = love.audio.newSource("Assets/Audio/kotoLoop.wav")
  enemy_death = love.audio.newSource("Assets/Audio/tengu.wav")
  bullet_sound = love.audio.newSource("Assets/Audio/talisman.wav")
  over_sound = love.audio.newSource("Assets/Audio/gameover.ogg")
  bgm:setLooping(true)
  bgm:play() -- Play BGM and Loop
  -- Set Game Font
  gameFont = love.graphics.newFont("Assets/Font/Harakiri.ttf", 30)
  love.graphics.setFont(gameFont)
  background = love.graphics.newImage("Assets/Images/bg.png") -- Background Img
  gate = love.graphics.newImage("Assets/Images/gate.png") -- Shrine Gate Img
  -- Player Settings
  player.x = love.graphics.getWidth() / 5
  player.y = love.graphics.getHeight() / 1.5
  player.ground = player.y
end

function love.update(dt)
  if player.alive == 0 then
    -- Player Controls
    if love.keyboard.isDown('d') then
      player.direction = 1
  		if player.x < (love.graphics.getWidth() - (player.img:getWidth() * player.sx / 2)) then
  		    player.x = player.x + (player.speed * dt)
  		end
  	elseif love.keyboard.isDown('a') then
      player.direction = -1
  		if player.x > player.img:getWidth() * player.sx / 2 then
  		    player.x = player.x - (player.speed * dt)
  		end
  	end
    if player.y_velocity ~= 0 then
      player.y = player.y + player.y_velocity * dt
      player.y_velocity = player.y_velocity - player.gravity * dt
    end
    if player.y > player.ground then
      player.y_velocity = 0
      player.y = player.ground
    end
    if player.y == player.ground then
      player.double_jump = 0
    end
    if love.mouse.isDown(1) and player.heat <= 0 then -- Bullets Pew Pew
    	table.insert(bullets, {
    	   x = player.x,
    		 y = player.y,
    		 dir = player.direction,
    		 speed = 800
    	})
      bullet_sound:play()
    	player.heat = player.heatp
      player.state = 1
    end
    -- Enemy Generation
    enemies.current_time = enemies.current_time - dt
    if enemies.current_time <= 0 then
      a, w = enemyControl()
      table.insert(enemies, {
    	   dx = 0,
    		 dy = 0,
    		 ran = love.math.random(100, love.graphics.getHeight() - 170),
         time = 0,
         amp = a,
         wave = w
    	})
      enemies.current_time = enemies.spawn_time
    end
    if player.state == 1 then
      player.anim_timer = player.anim_timer - dt
      if player.anim_timer <= 0 then
        player.state = 0
        player.anim_timer = 0.5
      end
    end
    player.heat = math.max(0, player.heat - dt)
    for i, o in ipairs(bullets) do
      o.x = o.x + (800 * dt) * o.dir
      if o.x > love.graphics.getWidth() or o.x < 0 then -- Remove Bullets if Out of Screen
        table.remove(bullets, i)
      end
    end
    for j, e in ipairs(enemies) do
      e.time = e.time + dt
      e.dx,e.dy = sineMove(e.time, 0, e.amp, e.wave) -- Enemy Movement Path
      e.dx = e.dx
    end
    -- Enemy Hit Detection
    for i, enemy in ipairs(enemies) do
      for j, bullet in ipairs(bullets) do
        if CheckCollision(love.graphics.getWidth() +  enemy.dx*-1, enemy.ran + enemy.dy, enemies.img:getWidth() * enemies.sx, enemies.img:getHeight() * enemies.sy, bullet.x, bullet.y, bullets.img:getWidth() * bullets.sx, bullets.img:getHeight() * bullets.sy) then
          table.remove(bullets, j)
          table.remove(enemies, i)
          enemy_death:play()
          player.score = player.score + 1
        end
      end
    end
    -- Check Enemy if Out of Screen
    for i, enemy in ipairs(enemies) do
      if enemy.dx >= love.graphics.getWidth() then
        table.remove(enemies, i)
        over_sound:play()
        player.alive = 1
        if player.score > player.high_score then
          player.high_score = player.score
        end
      end
    end
  end
end

function love.draw()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(background, 0, 0, 0, love.graphics.getWidth() / background:getWidth(), love.graphics.getHeight() / background:getHeight()) -- Set Background
  if player.alive == 0 then
    love.graphics.draw(gate, 20, love.graphics.getHeight() / 15, 0, 1, 1.25)  -- Set Gate
    --  Draw Player
    if player.state == 0 then
      love.graphics.draw(player.img, player.x, player.y, 0, player.sx * player.direction, player.sy, player.img:getWidth() * player.sx, 0)
    elseif player.state == 1 then
      love.graphics.draw(player.atk_img, player.x, player.y, 0, player.sx * player.direction, player.sy, player.atk_img:getWidth() * player.sx, 0)
    end
    -- Enemies
    for j, e in ipairs(enemies) do
      love.graphics.draw(enemies.img, love.graphics.getWidth() +  e.dx * -1, e.ran + e.dy, 0, enemies.sx, enemies.sy)
    end
    -- Bullets
    for i, o in ipairs(bullets) do
      love.graphics.draw(bullets.img, o.x, o.y, 0, bullets.sx * o.dir, bullets.sy, bullets.sy, bullets.img:getWidth() * bullets.sx, 0)
    end
  else
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Game Over", love.graphics.getWidth() / 2 - 50, love.graphics.getHeight() / 2)
    love.graphics.print("Press R to Restart", love.graphics.getWidth() / 2 - 80, love.graphics.getHeight() / 2 + 50)
  end
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("Score " .. player.score, 90, 15)
  love.graphics.print("High Score " .. player.high_score, 90, 45)
  if player.toggle_control == 0 then
    showControls()
  end
end

-- Function to Check Collision
function CheckCollision(x1, y1, w1, h1, x2, y2, w2, h2)
  return
    x1 < x2+w2 and
    x2 < x1+w1 and
    y1 < y2+h2 and
    y2 < y1+h1
end

-- Enemy Sine Wave Movement Function
function sineMove(time, angle, amplitude, waveLen)
  return
    math.cos(angle) * time * (waveLen / (2 * math.pi)) + ((amplitude / 2) * math.sin(time) * math.sin(angle)),
	  math.sin(angle) * time * (waveLen / (2 * math.pi)) - ((amplitude / 2) * math.sin(time) * math.cos(angle))
end

-- Player Jump and Double Jump
function love.keypressed(key)
  if key == "space" and player.alive == 0 then
    if player.double_jump == 0 then
      player.double_jump = 1
      player.y_velocity = player.jump_height
    elseif player.double_jump == 2 then
      player.y_velocity = player.jump_height * 2
      player.double_jump = 3
    end
  end
end

function love.keyreleased(key)
  if key == "space" and player.alive == 0 then
    if player.double_jump == 1 then
      player.double_jump = 2
    elseif player.double_jump == 2 then
      player.double_jump = 0
    end
  elseif key == "t" then
    if player.toggle_control == 0 then
      player.toggle_control = 1
    else
      player.toggle_control = 0
    end
  elseif key == "r" and player.alive == 1 then
    restartGame()
    player.alive = 0
  end
end

-- Amplitude, Wavelength and Spawn time for Enemy based on Score
function enemyControl()
  if player.score <= 5 then
    enemies.spawn_time = 3
    amp = 100
    wave = 600
  elseif player.score > 5 and player.score <= 10 then
    enemies.spawn_time = 2.5
    amp = math.random(200, 250)
    wave = math.random(800,900)
  elseif player.score > 10 and player.score <= 20 then
    enemies.spawn_time = 2
    amp = math.random(300, 350)
    wave = math.random(1000, 1100)
  else
    enemies.spawn_time = 1.8
    amp = math.random(400, 450)
    wave = math.random(1200,1300)
  end
  return
    amp, wave
end

function restartGame()
  -- Despawn all Enemies and Bullets
  for i, enemy in ipairs(enemies) do
    enemies[i] = nil
  end
  for j, bullet in ipairs(bullets) do
    bullets[j] = nil
  end
  -- Reset Values to Default
  player.x = love.graphics.getWidth() / 5
  player.y = love.graphics.getHeight() / 1.5
  player.ground = player.y
  player.y_velocity = 0
  player.double_jump = 0
  player.jump_timer = 0
  player.heat = 0
  player.heatp = 1
  player.direction = 1
  player.state = 0
  player.score = 0
  player.alive = 0
  enemies.current_time = 0
  enemies.spawn_time = 3
end

-- Show Player Controls
function showControls()
  text_x = love.graphics.getWidth() - 330
  love.graphics.print("Controls", text_x + 80, 15)
  love.graphics.print("T = Toggle Control Info", text_x, 45)
  love.graphics.print("A = Move Left", text_x, 75)
  love.graphics.print("D = Move Right", text_x, 105)
  love.graphics.print("Right Click = Shoot", text_x, 135)
  love.graphics.print("Space = Jump", text_x, 165)
  love.graphics.print("Space + Space = Double Jump", text_x, 195)
end
