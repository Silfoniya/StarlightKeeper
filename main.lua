-- Starlight Keeper

function love.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.4)

    -- Шрифты
    fontHUD = love.graphics.newFont("font.ttf", 24)
    fontTitle = love.graphics.newFont("font.ttf", 50)
    fontSmall = love.graphics.newFont("font.ttf", 20)
    
    -- === Загрузка звуков ===

    soundJump = love.audio.newSource("jump.wav", "static")
    soundCollect = love.audio.newSource("collect.wav", "static")
    soundDeliver = love.audio.newSource("deliver.wav", "static")

    -- Игровые переменные
    -- Начинаем игру с меню
    gameState = "menu" -- Возможные состояния: "menu", "playing", "win", "lose"
    levelGoal = 10
    gameTimer = 60
    starsDelivered = 0

    -- Настройка игрока
    player = {}
    player.x = 400
    player.y = 450
    player.width = 30
    player.height = 50
    player.speed = 250
    player.jump_force = -450
    player.vy = 0
    gravity = 1200
    player.is_on_ground = false
    player.starsCarried = 0

    -- Настройка звезд
    stars = {}
    star_speed = 150
    star_spawn_timer = 1
    star_spawn_interval = 1.5

    -- Луна
    moon = {}
    moon.width = 80
    moon.height = 80
    moon.x = 50
    moon.y = 50

    -- Платформы
    platforms = {}
    table.insert(platforms, {x = 0, y = 550, width = 800, height = 50})
    table.insert(platforms, {x = 550, y = 430, width = 150, height = 20})
    table.insert(platforms, {x = 300, y = 310, width = 150, height = 20})
    table.insert(platforms, {x = 100, y = 200, width = 120, height = 20})
end

-- Функция для сброса игры в начальное состояние
function resetGame()
    -- Не вызываем love.load(), чтобы не перезагружать шрифты и звуки.
    -- Вместо этого просто сбрасываем переменные.
    gameState = "playing"
    gameTimer = 60
    starsDelivered = 0
    player.x = 400
    player.y = 450
    player.vy = 0
    player.starsCarried = 0
    stars = {} -- Очищаем таблицу от старых звезд
end

function checkCollision(obj1, obj2)
    return obj1.x < obj2.x + obj2.width and obj2.x < obj1.x + obj1.width and
           obj1.y < obj2.y + obj2.height and obj2.y < obj1.y + obj1.height
end

function spawnStar()
    local star = {}
    star.width = 20; star.height = 20
    star.x = math.random(0, love.graphics.getWidth() - star.width)
    star.y = -star.height
    table.insert(stars, star)
end

function love.update(dt)
    -- === НОВОЕ: Логика для главного меню ===
    if gameState == "menu" then
        if love.keyboard.isDown("return") then
            resetGame() -- Начинаем игру
        end
    
    -- === Логика основного игрового процесса ===
    elseif gameState == "playing" then
        -- Горизонтальное движение
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
            player.x = player.x + player.speed * dt
        elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
            player.x = player.x - player.speed * dt
        end

        -- Вертикальная физика
        player.vy = player.vy + gravity * dt
        player.y = player.y + player.vy * dt
        player.is_on_ground = false
        for i, p in ipairs(platforms) do
            if checkCollision(player, p) and player.vy > 0 then
                player.y = p.y - player.height
                player.vy = 0
                player.is_on_ground = true
                break
            end
        end

        -- Прыжок
        if love.keyboard.isDown("space") and player.is_on_ground then
            player.vy = player.jump_force
            player.is_on_ground = false
            soundJump:play() -- << ЗВУК ПРЫЖКА
        end

        -- Логика звезд
        star_spawn_timer = star_spawn_timer - dt
        if star_spawn_timer <= 0 then spawnStar() star_spawn_timer = star_spawn_interval end
        for i = #stars, 1, -1 do
            local star = stars[i]
            star.y = star.y + star_speed * dt
            if checkCollision(player, star) then
                player.starsCarried = player.starsCarried + 1
                soundCollect:play() -- << ЗВУК СБОРА
                table.remove(stars, i)
            elseif star.y > love.graphics.getHeight() then
                table.remove(stars, i)
            end
        end

        -- Доставка звезд
        if checkCollision(player, moon) and player.starsCarried > 0 then
            starsDelivered = starsDelivered + player.starsCarried
            player.starsCarried = 0
            soundDeliver:play() -- << ЗВУК ДОСТАВКИ
        end

        -- Таймер и условия победы/поражения
        gameTimer = gameTimer - dt
        if starsDelivered >= levelGoal then gameState = "win"
        elseif gameTimer <= 0 then gameTimer = 0 gameState = "lose" end
    
    -- === Логика для экранов победы/поражения ===
    elseif (gameState == "win" or gameState == "lose") and love.keyboard.isDown("return") then
        resetGame() -- Начинаем заново
    end
end

function love.draw()
    -- === НОВОЕ: Отрисовка главного меню ===
    if gameState == "menu" then
        love.graphics.setFont(fontTitle)
        love.graphics.printf("Starlight Keeper", 0, 150, love.graphics.getWidth(), "center")
        love.graphics.setFont(fontSmall)
        love.graphics.printf("Нажмите Enter, чтобы начать", 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("Управление: A/D - движение, Пробел - прыжок", 0, 450, love.graphics.getWidth(), "center")
    
    -- === Отрисовка всего остального (игра, экраны победы/поражения) ===
    else
        -- Игровой мир
        love.graphics.setColor(0.4, 0.8, 0.4)
        for i, p in ipairs(platforms) do love.graphics.rectangle("fill", p.x, p.y, p.width, p.height) end
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.circle("fill", moon.x + moon.width / 2, moon.y + moon.height / 2, moon.width / 2)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
        love.graphics.setColor(1, 1, 0.4)
        for i, star in ipairs(stars) do love.graphics.rectangle("fill", star.x, star.y, star.width, star.height) end

        -- Интерфейс (HUD)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(fontHUD)
        love.graphics.print("Собрано звезд: " .. starsDelivered .. " / " .. levelGoal, 10, 10)
        love.graphics.print("В руках: " .. player.starsCarried, 10, 40)
        love.graphics.print("Время до рассвета: " .. math.floor(gameTimer), love.graphics.getWidth() - 300, 10)

        -- Экраны Победы и Поражения
        if gameState == "win" then
            love.graphics.setFont(fontTitle)
            love.graphics.printf("Вы сохранили ночь!", 0, 250, love.graphics.getWidth(), "center")
            love.graphics.setFont(fontSmall)
            love.graphics.printf("Нажмите Enter, чтобы сыграть снова", 0, 310, love.graphics.getWidth(), "center")
        elseif gameState == "lose" then
            love.graphics.setFont(fontTitle)
            love.graphics.printf("Рассвет наступил...", 0, 250, love.graphics.getWidth(), "center")
            love.graphics.setFont(fontSmall)
            love.graphics.printf("Нажмите Enter, чтобы попробовать еще раз", 0, 310, love.graphics.getWidth(), "center")
        end
    end
end