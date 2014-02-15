# Block Buster
#
# Inspired by http://www.adityaravishankar.com

# Variable Definitions

canvas  = document.getElementById "canvas"
context = canvas.getContext "2d"

paddleX = 200
paddleY = 460

paddleWidth = 50;
paddleHeight = 20;

paddleDeltaX = 0;
paddleDeltaY = 0;

ballX = 300;
ballY = 300;
ballRadius = 6;

bricksPerRow = 8
brickHeight = 20
brickWidth = canvas.width / bricksPerRow
bricks = [
  [1, 1, 1, 1, 1, 1, 1, 2]
  [1, 1, 3, 1, 0, 1, 1, 1]
  [2, 1, 2, 1, 2, 1, 0, 1]
  [1, 2, 1, 1, 0, 3, 1, 1]
]

score = 0

ballDeltaX    = null
ballDeltaY    = null
paddleMove    = null
paddleDeltaX  = null
paddleSpeedX  = 10
keys          = []
friction      = 0.8

# Engine

fps           = 60
interval      = 1000 / fps
mainLoop      = null
now           = null


# Game Mechanics

((window) ->
  lastTime = 0
  vendors = ["webkit", "moz"]
  requestAnimationFrame = window.requestAnimationFrame
  cancelAnimationFrame = window.cancelAnimationFrame
  i = vendors.length

  # try to un-prefix existing raf
  while --i >= 0 and not requestAnimationFrame
    requestAnimationFrame = window[vendors[i] + "RequestAnimationFrame"]
    cancelAnimationFrame = window[vendors[i] + "CancelAnimationFrame"]

  # polyfill with setTimeout fallback
  # heavily inspired from @darius gist mod: https://gist.github.com/paulirish/1579671#comment-837945
  if not requestAnimationFrame or not cancelAnimationFrame
    requestAnimationFrame = (callback) ->
      now = Date.now()
      nextTime = Math.max(lastTime + 16, now)
      setTimeout (->
        callback lastTime = nextTime
      ), nextTime - now

    cancelAnimationFrame = clearTimeout

  # export to window
  window.requestAnimationFrame = requestAnimationFrame
  window.cancelAnimationFrame = cancelAnimationFrame
) window

drawPaddle = ->
    context.fillStyle = "black"
    context.fillRect(paddleX,paddleY,paddleWidth,paddleHeight)

drawBall = ->
    context.fillStyle = "black"
    # Context.beginPath when you draw primitive shapes
    context.beginPath()

    # Draw arc at center ballX, ballY with radius ballRadius,
    # From 0 to 2xPI radians (full circle)
    context.arc(ballX,ballY,ballRadius,0,Math.PI*2,true)

    # Fill up the path that you just drew
    context.fill();

createBricks = ->
  i = 0

  while i < bricks.length
    j = 0

    while j < bricks[i].length
      drawBrick j, i, bricks[i][j]
      j++
    i++

# draw a single brick
drawBrick = (x, y, type) ->
  switch type # if brick is still visible; three colors for three types of bricks
    when 1
      context.fillStyle = "orange"
    when 2
      context.fillStyle = "rgb(100,200,100)"
    when 3
      context.fillStyle = "rgba(50,100,50,.5)"
    else
      context.clearRect x * brickWidth, y * brickHeight, brickWidth, brickHeight
  if type

    #Draw rectangle with fillStyle color selected earlier
    context.fillRect x * brickWidth, y * brickHeight, brickWidth, brickHeight

    # Also draw blackish border around the brick
    context.strokeRect x * brickWidth + 1, y * brickHeight + 1, brickWidth - 2, brickHeight - 2


displayScoreBoard = ->
  #Set the text font and color
  context.fillStyle = "black"
  context.font = "12px Helvetica"

  #Clear the bottom 30 pixels of the canvas
  context.clearRect 0, canvas.height - 30, canvas.width, 30

  # Write Text 5 pixels from the bottom of the canvas
  context.fillText "Score: " + score, 20, canvas.height - 25

moveBall = ->
  ballDeltaY = -ballDeltaY  if ballY + ballDeltaY - ballRadius < 0 or collisionYWithBricks()

  ballDeltaX = -ballDeltaX  if (ballX + ballDeltaX - ballRadius < 0) or (ballX + ballDeltaX + ballRadius > canvas.width) or collisionXWithBricks()

  end() if ballY + ballDeltaY + ballRadius > canvas.height

  ballDeltaY = -ballDeltaY if ballX + ballDeltaX >= paddleX and ballX + ballDeltaX <= paddleX + paddleWidth  if ballY + ballDeltaY + ballRadius >= paddleY

  # Move the ball
  ballX = ballX + ballDeltaX
  ballY = ballY + ballDeltaY

movePaddle = ->

  if keys[39]
      if paddleDeltaX < paddleSpeedX
          paddleDeltaX += 2

  if keys[37]
      if paddleDeltaX > -paddleSpeedX
          paddleDeltaX -= 2

  paddleDeltaX *= friction;

  # If paddle reaches the side of the screen, then don't let it move any further
  paddleDeltaX = 0  if paddleX + paddleDeltaX < 0 or paddleX + paddleDeltaX + paddleWidth > canvas.width
  paddleX = paddleX + paddleDeltaX

f2T = (Delta, Speed) ->
    (Speed * Delta) * (fps / 1000);


collisionXWithBricks = ->
  bumpedX = false
  i = 0

  while i < bricks.length
    j = 0

    while j < bricks[i].length
      if bricks[i][j] # if brick is still visible
        brickX = j * brickWidth
        brickY = i * brickHeight

        # barely touching from left

        # barely touching from right
        if ((ballX + ballDeltaX + ballRadius >= brickX) and (ballX + ballRadius <= brickX)) or ((ballX + ballDeltaX - ballRadius <= brickX + brickWidth) and (ballX - ballRadius >= brickX + brickWidth))
          if (ballY + ballDeltaY - ballRadius <= brickY + brickHeight) and (ballY + ballDeltaY + ballRadius >= brickY)

            # weaken brick and increase score
            explodeBrick i, j
            bumpedX = true
      j++
    i++
  bumpedX

collisionYWithBricks = ->
  bumpedY = false
  i = 0

  while i < bricks.length
    j = 0

    while j < bricks[i].length
      if bricks[i][j] # if brick is still visible
        brickX = j * brickWidth
        brickY = i * brickHeight

        # barely touching from below

        # barely touching from above
        if ((ballY + ballDeltaY - ballRadius <= brickY + brickHeight) and (ballY - ballRadius >= brickY + brickHeight)) or ((ballY + ballDeltaY + ballRadius >= brickY) and (ballY + ballRadius <= brickY))
          if ballX + ballDeltaX + ballRadius >= brickX and ballX + ballDeltaX - ballRadius <= brickX + brickWidth

            # weaken brick and increase score
            explodeBrick i, j
            bumpedY = true
      j++
    i++
  bumpedY

explodeBrick = (i, j) ->
  # First weaken the brick (0 means brick has gone)
  bricks[i][j]--
  if bricks[i][j] > 0
    # The brick is weakened but still around. Give a single point.
    score++
  else
    # give player an extra point when the brick disappears
    score += 2

animate = ->
    context.clearRect(0,0,canvas.width,canvas.height)
    createBricks()
    moveBall()
    movePaddle()
    drawPaddle()
    drawBall()

    displayScoreBoard()

start = ->
    mainLoop = requestAnimationFrame start
    animate()

    # Start Tracking Keystokes
    document.body.addEventListener "keydown", (e) ->
        keys[e.keyCode] = true

    document.body.addEventListener "keyup", (e) ->
        keys[e.keyCode] = false

end = ->
    cancelAnimationFrame mainLoop
    mainLoop = null
    context.fillText('The End!',canvas.width/2,canvas.height/2)

ballDeltaY = -6
ballDeltaX = -4
paddleMove = "NONE"
start()