--Breakout Game based on Breakout in "Corona SDK Mobile Game development - Fernandez, Michelle, M."
--Adapted by Rob Englebright to make more use of the physics engine and Graphics2.0

-- Hide Status Bar
display.setStatusBar(display.HiddenStatusBar)

-- Physics Engine - Box 2D
		
local physics = require "physics"
physics.start() -- other options "pause", or "stop" which destroys the world
physics.setGravity(0, 0) -- gx, gy -- gy = 9.8 for normal gravity
physics.setScale(60) -- pixel/metre ratio - higher for hi res devices

physics.setDrawMode("hybrid") -- other options "debug" or "normal"
--[[
    orange - dynamic physics bodies (default)
    dark blue - kinematic physics bodies
    green - static physics bodies (ground, walls)
    gray - "sleeping" body - due to lack of activity
    light blue - joints
]]--

--Not used in this app
--physics.setPositionIterations(8) -default - engine position calculation accuracy/frame
--physics.setVelocityIterations(3) -default- engine velocity calculation accuracy/frame

-- Accelerometer
system.setAccelerometerInterval( 100 ) -- range is 10Hz to 100Hz, lower promotes better battery life

-- Menu Screen
local menuScreenGroup	-- display.newGroup()
local mmScreen
local playBtn

-- Game Screen
local background
local paddle
local brick
local ball

-- Score/Level Text
local scoreText
local scoreNum
local levelText
local levelNum

-- alertDisplayGroup
local alertDisplayGroup	 -- display.newGroup()
local alertBox
local conditionDisplay
local messageText

-- Variables
local width = display.contentWidth
local height = display.contentHeight
local _W = display.contentWidth / 2
local _H = display.contentHeight / 2
local bricks = display.newGroup()
local brickWidth = 50
local brickHeight = 20
local row
local column
local score = 0
local scoreIncrease = 1
local currentLevel
local vx = 3
local vy = -3
local gameEvent = ""

local isSimulator = "False" == system.getInfo("environment")

-- Main Function
function main()
	mainMenu()
end

function mainMenu()	
	menuScreenGroup = display.newGroup() 

	mmScreen = display.newText( "Black and White Breakout", _W, _H, "Helvetica Neue UltraLight", 48 ) 
	mmScreen.x = _W --set main menu x coordinate
	--mmScreen.y = _H --set main menu y coordinate
	
	--TODO change referencePoints to Anchor Points
	-- change images to text -- display.newText( [parentGroup,] text, x, y, font, fontSize )
	playBtn = display.newText( "Play", _W, _H + 50, "Helvetica Neue UltraLight", 48)
	playBtn:setReferencePoint(display.CenterReferencePoint) --set reference point 
	playBtn.x = _W --in Graphics 2 this all goesout the window, as central position
	playBtn.name = "playbutton"

	menuScreenGroup:insert(mmScreen)
	menuScreenGroup:insert(playBtn)
	
	-- Button Listeners	
	playBtn:addEventListener("tap", loadGame)
end


function loadGame(event)
	if event.target.name == "playbutton" then
	
		-- Start Game
				
		transition.to(menuScreenGroup,{time = 0, alpha=0, 
                onComplete = addGameScreen})
		
		playBtn:removeEventListener("tap", loadGame)
	end
end

function addGameScreen()

	--TODO- find out why the fill color and stroke width etc aren't working
	background = display.newRect( 0, 0, width, height)

	--TODO change background colour to match level
	background:setFillColor( 200, 20, 20)
    --background:setStrokeColor( 1, 0, 0 )
	
	--TODO change this to a native vector shape 
	--use  -- display.newRect( [parentGroup,] left, top, width, height )
	paddle = display.newRect(_W, _H + 50, 80, 2 )
	paddle.x = _W; paddle.y = _H + 50
	paddle.name = "paddle"

	--TODO change location coords to relative value
	--use --display.newCircle( xCenter, yCenter, radius )
	ball = display.newCircle( 240, 290, 2 )
	ball.name = "ball"
	
	-- Text
	-- The Narrow system font in iOS7 is "Helvetica Neue UltraLight"
	--TODO change the location of the text by using Anchor points
	scoreText = display.newText("Score:", 5, 2, "Helvetica Neue UltraLight", 48)
	scoreText:setTextColor(255, 255, 255, 255)
	
	scoreNum = display.newText("0", 250, 2, "Helvetica Neue UltraLight", 48)
	scoreNum:setTextColor(255, 255, 255, 255)
	
	levelText = display.newText("Level:", 800, 2, "Helvetica Neue UltraLight", 48)
	levelText:setTextColor(255, 255, 255, 255)
	
	levelNum = display.newText("1", 960, 2, "Helvetica Neue UltraLight", 48)
	levelNum:setTextColor(255, 255, 255, 255)
	
	-- Build Level Bricks 
	
	gameLevel1() 
	
	-- Start Listener 
	
	background:addEventListener("tap", startGame)
end

-- Used to drag the paddle on the simulator

function dragPaddle(event)
	
	if isSimulator then
	
		if event.phase == "began" then
			moveX = event.x - paddle.x
		elseif event.phase == "moved" then
			paddle.x = event.x - moveX
		end
	
		if((paddle.x - paddle.width * 0.5) < 0) then
			paddle.x = paddle.width * 0.5
		elseif((paddle.x + paddle.width * 0.5) > display.contentWidth) then
			paddle.x = display.contentWidth - paddle.width * 0.5
		end
		
	end
	
end

function movePaddle(event)

	-- Accelerometer Movement
	
	--must be yGravity since it's landscape
	paddle.x = display.contentCenterX - (display.contentCenterX * (event.yGravity*3))
	
	
	-- Wall Borders 
	
	if((paddle.x - paddle.width * 0.5) < 0) then
		paddle.x = paddle.width * 0.5
	elseif((paddle.x + paddle.width * 0.5) > display.contentWidth) then
		paddle.x = display.contentWidth - paddle.width * 0.5
	end
end


function bounce()
	vy = -3
	
	-- Paddle Collision, check the which side of the paddle the ball hits, left, right 
	
	if((ball.x + ball.width * 0.5) < paddle.x) then
		vx = -vx
	elseif((ball.x + ball.width * 0.5) >= paddle.x) then
		vx = vx
	end
end

function startGame()
	-- Physics
	physics.addBody(paddle, "static", {density = 1, friction = 0, bounce = 0})
	physics.addBody(ball, "dynamic", {density = 1, friction = 0, bounce = 0})
	
	background:removeEventListener("tap", startGame)
	gameListeners("add")
end

-- HOW TO BUILD BLOCKS
--turn level into a function that takes it's level from outside - and rows and columns from a lookup?
--

function gameLevel1()

	currentLevel = 1

	bricks:toFront()
	
	local numOfRows = 4
	local numOfColumns = 4
	local brickPlacement = {x = (_W) - (brickWidth * numOfColumns ) / 2  + 20, y = 50}
	
	for row = 0, numOfRows - 1 do
		for column = 0, numOfColumns - 1 do
		
			-- Create a brick
			--TODO fix vector bricks
			local brick = display.newRect( brickPlacement.x + (column * brickWidth), brickPlacement.y + (row * brickHeight), 35, 15 )
			brick:setFillColor( 0, 0, 0 ) --fill is black
			brick:setStrokeColor( 255, 255, 255 ) -- outline our bricks in white
			brick.strokeWidth = 2
			brick.name = "brick"
			physics.addBody(brick, "static", {density = 1, friction = 0, bounce = 0})
			bricks.insert(bricks, brick)

		end
	end
end

-- TODO switch out this and get the change of level pararmeters from a table. 1-10 decides bricks etc. 20, 30 etc decides sizeof paddle -speed 
function gameLevel2()

	currentLevel = 2

	bricks:toFront()
	
	local numOfRows = 5
	local numOfColumns = 8

	local brickPlacement = {x = (_W) - (brickWidth * numOfColumns ) / 2  + 20, y = 50}
	
	for row = 0, numOfRows - 1 do
		for column = 0, numOfColumns - 1 do
		
			-- Create a brick
			local brick = display.newImage("brick.png")
			brick.name = "brick"
			brick.x = brickPlacement.x + (column * brickWidth)
			brick.y = brickPlacement.y + (row * brickHeight)
			physics.addBody(brick, "static", {density = 1, friction = 0, bounce = 0})
			bricks.insert(bricks, brick)

		end
	end
end

function gameListeners(event)
	if event == "add" then
		Runtime:addEventListener("accelerometer", movePaddle)
		Runtime:addEventListener("enterFrame", updateBall)
		paddle:addEventListener("collision", bounce)
		ball:addEventListener("collision", removeBrick)
		-- Used to drag the paddle on the simulator
		paddle:addEventListener("touch", dragPaddle)
		
	elseif event == "remove" then
		Runtime:removeEventListener("accelerometer", movePaddle)
		Runtime:removeEventListener("enterFrame", updateBall)
		paddle:removeEventListener("collision", bounce)
		ball:removeEventListener("collision", removeBrick)
		-- Used to drag the paddle on the simulator
		paddle:removeEventListener("touch", dragPaddle)
		
	end
end

--BRICK REMOVAL

function removeBrick(event)
	
	-- Check the which side of the brick the ball hits, left, right  
  
    if event.other.name == "brick" and ball.x + ball.width * 0.5 < event.other.x + event.other.width * 0.5 then
        vx = -vx 
    elseif event.other.name == "brick" and ball.x + ball.width * 0.5 >= event.other.x + event.other.width * 0.5 then
        vx = vx 
    end
    
	-- Bounce, Remove
	if event.other.name == "brick" then
		vy = vy * -1
		event.other:removeSelf()
		event.other = nil
		bricks.numChildren = bricks.numChildren - 1
		-- Score
		score = score + 1
		scoreNum.text = score * scoreIncrease
		scoreNum:setReferencePoint(display.CenterLeftReferencePoint)
		scoreNum.x = 250 
	end
	
	-- Check if all bricks are destroyed
	
	if bricks.numChildren < 0 then
		alertScreen("YOU WIN!", "Continue")
		gameEvent = "win"
	end
end

-- BALL FUNCTION

function updateBall()

	-- Ball Movement 

	ball.x = ball.x + vx
	ball.y = ball.y + vy
	
	-- Wall Collision 
	
	if ball.x < 0 or ball.x + ball.width > display.contentWidth then  
		vx = -vx
	end--Left
	
	if ball.y < 0  then 
		vy = -vy
	end--Up
	
	if ball.y + ball.height > paddle.y + paddle.height then 
		alertScreen("YOU LOSE!", "Play Again") gameEvent = "lose" 
	end--down/lose
end


-- RESET LEVEL

function changeLevel1()

	-- Clear Level Bricks 
	
	bricks:removeSelf()
	
	bricks.numChildren = 0
	bricks = display.newGroup()

	-- Remove Alert 
	
	alertBox:removeEventListener("tap", restart)
	alertDisplayGroup:removeSelf()
	alertDisplayGroup = nil
	
	-- Reset Ball and Paddle position 
	
	ball.x = (display.contentWidth * 0.5) - (ball.width * 0.5)
	ball.y = (paddle.y - paddle.height) - (ball.height * 0.5) -2
	
	paddle.x = display.contentWidth * 0.5
	
	-- Redraw Bricks 
	
	gameLevel1()	
	
	-- Start
	
	background:addEventListener("tap", startGame)
end

function changeLevel2()

	-- Clear Level Bricks 
	
	bricks:removeSelf()
	
	bricks.numChildren = 0
	bricks = display.newGroup()

	-- Remove Alert 
	
	alertBox:removeEventListener("tap", restart)
	alertDisplayGroup:removeSelf()
	alertDisplayGroup = nil
	
	-- Reset Ball and Paddle position 
	
	ball.x = (display.contentWidth * 0.5) - (ball.width * 0.5)
	ball.y = (paddle.y - paddle.height) - (ball.height * 0.5) -2
	
	paddle.x = display.contentWidth * 0.5
	
	-- Redraw Bricks 
	
	gameLevel2()
	
	
	-- Start	
	background:addEventListener("tap", startGame)
end


function alertScreen(title, message)
	gameListeners("remove")
	
	--TODO: use display.newRect( x, y, width, height )
	alertBox = display.newRect(_W -150,_H - 100, 300, 200)
	--TODO add stroke and fill to box so can see text
	transition.from(alertBox, {time = 500, xScale = 0.5, yScale = 0.5, transition = easing.outExpo})
	
	conditionDisplay = display.newText(title, 0, 0, "Helvetica Neue Light", 48)
	conditionDisplay:setTextColor(0,0,0,255) --set to black
	conditionDisplay.xScale = 0.5
	conditionDisplay.yScale = 0.5
	conditionDisplay:setReferencePoint(display.CenterReferencePoint)
	conditionDisplay.x = display.contentCenterX
	conditionDisplay.y = display.contentCenterY - 15
	
	messageText = display.newText(message, 0, 0, "Helvetica Neue Light", 48)
	messageText:setTextColor(0,0,0,255) --set to black
	messageText.xScale = 0.5
	messageText.yScale = 0.5
	messageText:setReferencePoint(display.CenterReferencePoint)
	messageText.x = display.contentCenterX
	messageText.y = display.contentCenterY + 15

	alertDisplayGroup = display.newGroup()
	alertDisplayGroup:insert(alertBox)
	alertDisplayGroup:insert(conditionDisplay)
	alertDisplayGroup:insert(messageText)
	
	alertBox:addEventListener("tap", restart)
end

-- WIN/LOSE ARGUMENT
function restart()
	if gameEvent == "win" and currentLevel == 1 then
		currentLevel = currentLevel + 1
		changeLevel2()--next level
		levelNum.text = tostring(currentLevel)
	elseif gameEvent == "win" and currentLevel == 2 then	
		alertScreen("  Game Over", "  Congratulations!")
		gameEvent = "completed"
	elseif gameEvent == "lose" and currentLevel == 1 then
		score = 0
		scoreNum.text = "0"
		changeLevel1()--same level
	elseif gameEvent == "lose" and currentLevel == 2 then
		score = 0
		scoreNum.text = "0"
		changeLevel2()--same level
	elseif gameEvent == "completed" then
		alertBox:removeEventListener("tap", restart)
	end
end

main()