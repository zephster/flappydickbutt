//
//  GameScene.swift
//  FlappyTest
//
//  Created by brandon on 7/27/15.
//  Copyright (c) 2015 cbcoding. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate
{
    var score:Int = 0

    // just define the textures, they are added to SKSpriteNodes when the object is created
    let heroTexture     = SKTexture(imageNamed: "dickbutt")
    let skyTexture      = SKTexture(imageNamed: "sky")
    let groundTexture   = SKTexture(imageNamed: "ground")
    let pipeUpTexture   = SKTexture(imageNamed: "PipeUp")
    let pipeDownTexture = SKTexture(imageNamed: "PipeDown")

    let skyColor = SKColor(red: 0, green: 191, blue: 255, alpha: 1)

    // collisions and such on the heros physicsBody use bitmasks to determine stuff
    // so by declaring each type of category i want as ints bit shifted in increments, i can
    // determine which objects are involved in a collision
    // each bitmask is defaulted to either 0x00000000 or 0xFFFFFFFF, obv 32bits
    // so i can have a total of 32 different categories
    let heroBitMask: UInt32    = 1 << 0 // 0b0001
    let pipeBitMask: UInt32    = 1 << 1 // 0b0010
    let groundBitMask: UInt32  = 1 << 2 // 0b0100
    let pipeGapBitMask: UInt32 = 1 << 3 // 0b1000

    // gap between top and bottom pipes
    let pipeGap:CGFloat = 150.0

    // z-indexes of stuff
    let groundZpos:CGFloat = 0
    let skyZpos:CGFloat    = -2
    let pipeZpos:CGFloat   = -1

    // dickbutt!
    var hero: SKSpriteNode!

    // node that contains the ground and sky's generated nodes
    var environmentNode = SKNode()

    // node that contains pipes, physics collisions with pipe nodes
    var pipesNode = SKNode()

    // action that moves the pipes, then removes once off-screen
    var pipeNodeAnimation: SKAction!

    // UI stuff
    let scoreLabel = SKLabelNode(text: "0")
    let retryButton = SKLabelNode(text: "retry")



    // scene just loaded
    override func didMoveToView(view: SKView)
    {
        self.backgroundColor = self.skyColor

        // set world physics
        // x, positive = right, negative = left
        // y, positive = up, negative = down
        self.physicsWorld.gravity         = CGVector(dx: 0, dy: -8)
        self.physicsWorld.contactDelegate = self

        self.heroTexture.filteringMode   = SKTextureFilteringMode.Linear
        self.skyTexture.filteringMode    = SKTextureFilteringMode.Nearest
        self.groundTexture.filteringMode = SKTextureFilteringMode.Nearest

        self.hero = self.setupDickbutt()
        self.setupGround()
        self.setupBackground()
        self.setupPipes()

        // score label
        self.scoreLabel.fontSize  = 100
        self.scoreLabel.fontColor = UIColor.whiteColor()
        self.scoreLabel.position  = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 10)
        self.addChild(self.scoreLabel)


        // retry button
        self.retryButton.fontSize  = 50
        self.retryButton.name      = "retryButton"
        self.retryButton.fontColor = UIColor.redColor()
        self.retryButton.position  = CGPoint(x: (self.frame.size.width / 2) + 125, y: self.frame.size.height / 8.5)
    }

    // handle touch inputs
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        // because it's falling, it has velocity. change it to 0
        self.hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)

        // then apply a force upwards
        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))

        for touch: AnyObject in touches
        {
            let touchLocation = touch.locationInNode(self)

            // if the touch location is within the bounds of the retry button
            if self.retryButton.containsPoint(touchLocation)
            {
                self.gameRestart()
            }

            // if it's in the start button
            // TODO: start button
        }
    }

    // collision detection
    func didBeginContact(contact: SKPhysicsContact)
    {
        // bitwise OR the two contacting bodies, then compare
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // check if the two bodies are hero and pipeGap (increment score)
        if contactMask == self.heroBitMask | self.pipeGapBitMask
        {
            self.incrementScore()

            // remove the bitmask on this pipe node, to prevent multiple triggers
            contact.bodyB.categoryBitMask = 0
        }
            // check if the two bodies are hero and pipe (game over)
        else if contactMask == self.heroBitMask | self.pipeBitMask
        {
            // if retry button isn't on the screen already (also prevents multiple triggers)
            if self.retryButton.parent == nil
            {
                self.gameOver()
            }
        }
    }


    // dickbutt setup
    // TODO: prevent dickbutt from going off-screen (top)
    func setupDickbutt() -> SKSpriteNode
    {
        let hero      = SKSpriteNode(texture: self.heroTexture)
        hero.position = CGPoint(x: self.frame.size.width * 0.33, y: self.frame.size.height * 0.75)

        // set the "hitbox" for physics interactions
        // hero.physicsBody = SKPhysicsBody(rectangleOfSize: hero.size) // square hitbox
        hero.physicsBody = SKPhysicsBody(texture: self.heroTexture, size: hero.size) // object-shape hitbox
        hero.physicsBody?.allowsRotation = false

        // set this value so when collission happens, i can test the "category" property to determine
        // what to do, depending on what object gets hit, defined below
        hero.physicsBody?.categoryBitMask = self.heroBitMask

        // determines which objects hero is capable of colliding and interacting with (bouncing off, etc)
        // don't need | self.pipeCat because upon contacting a pipe, it's event (below) will fire and the game will end
        hero.physicsBody?.collisionBitMask = self.groundBitMask

        // determines which objects send an event when collided with (without collisionBitMask, objects would pass through but still be detected)
        // don't need | self.levelCat because i don't need an event for touching the ground
        hero.physicsBody?.contactTestBitMask = self.pipeBitMask

        // add to scene
        self.addChild(hero)
        return hero
    }

    // ground setup
    func setupGround()
    {
        let groundTexSize   = self.groundTexture.size()
        let groundTexWidth  = groundTexSize.width
        let groundTexHeight = groundTexSize.height

        self.log("setupGround: groundTexSize: \(groundTexSize)")

        // scale up groundTex cause its low-res lol
        // if they were full-res i wouldn't have to
        // this is used when adding ground texture sprites to the scrollNode
        let scale:CGFloat = 2.0

        // define animations!
        // lower number = faster interval (duh)
        let groundMoveTime = NSTimeInterval(6.75)

        // move ground to the left (negative x-axis) on a timer, defined above
        let moveGround = SKAction.moveByX(-groundTexWidth * scale, y: 0, duration: groundMoveTime)

        // reset ground so it looks like its continuous
        let resetGround = SKAction.moveByX(groundTexWidth * scale, y: 0, duration: 0.0)

        // set the animation sequence order
        let groundSequence = SKAction.sequence([moveGround, resetGround])

        // this is the "main" action that gets set on the sprite, that is a sequence of the above 2 actions
        let groundAnimation = SKAction.repeatActionForever(groundSequence)

        // add enough sprites to the scrolling node so you dont run out before it resets
        // i < 2.0 * self.frame.size.width / (groundTexWidth * 2)
        // if scale = 2, above = 3.04, below would iterate 3 times, could be coincidence
        for var i:CGFloat = 0; i <= scale; i++
        {
            // sprite.size = groundTex.size (336 x 112 for that image)
            let sprite = SKSpriteNode(texture: self.groundTexture)

            // scale sprite.size to fill more screen
            sprite.setScale(scale)

            let spriteX = i * sprite.size.width
            let spriteY = sprite.size.height / scale
            self.log("setupGround: sprite x,y: \(spriteX), \(spriteY)")

            // i * width to stagger right, height / 2 because scale
            sprite.position = CGPoint(x: spriteX, y: spriteY)

            // z-index
            sprite.zPosition = self.groundZpos

            sprite.runAction(groundAnimation)
            self.environmentNode.addChild(sprite)
        }

        // groundNode is the physics body that gets collided with, groundTexHeight = sprite.height/2 (cause of scale)
        // the reason it's this way is because having each sprite have it's own physicsbody would be more work
        let groundNode = SKNode()
        groundNode.position = CGPoint(x: 0, y: groundTexHeight)
        groundNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: self.frame.size.width, height: groundTexHeight * scale))
        groundNode.physicsBody?.dynamic = false
        groundNode.physicsBody?.categoryBitMask = self.groundBitMask

        // scrollNode and groundNode are entirely separate things that just happen to reside in the same coordinate-space (for obv reasons)
        self.addChild(groundNode)
        self.addChild(self.environmentNode)
    }

    // background setup
    func setupBackground()
    {
        let skyTextureSize  = self.skyTexture.size()
        let skyTextureWidth = skyTextureSize.width
        let scale:CGFloat   = 2.0
        let skyMoveTime     = NSTimeInterval(40)

        let moveSky      = SKAction.moveByX(-skyTextureWidth * scale, y: 0, duration: skyMoveTime)
        let resetSky     = SKAction.moveByX(skyTextureWidth * scale, y: 0, duration: 0.0)
        let skySequence  = SKAction.sequence([moveSky, resetSky])
        let skyAnimation = SKAction.repeatActionForever(skySequence)

        self.log("setupSkyLine: skyTextureSize: \(skyTextureSize)")

        for var i:CGFloat = 0; i <= scale; i++
        {
            let sprite = SKSpriteNode(texture: self.skyTexture)
            sprite.setScale(scale)

            // i * width to stagger right, height = sprite.height * scale - ground.height
            let spriteX = i * sprite.size.width
            let spriteY = (sprite.size.height * scale) - self.groundTexture.size().height

            self.log("setupSkyLine: sprite x,y: \(spriteX), \(spriteY)")

            sprite.position  = CGPoint(x: spriteX, y: spriteY)

            // everything else resides on z-position 0
            sprite.zPosition = self.skyZpos

            sprite.runAction(skyAnimation)
            self.environmentNode.addChild(sprite)
        }
    }

    // pipes setup
    func setupPipes()
    {
        // first, set up the pipe animations themselves
        // set to a class property so it can be used by the pipe objects,
        // it's only configured (once) here, instead of every spawn (that'd be dumb)
        self.pipeNodeAnimation = self.setupPipeNodeAnimation()

        // now, set up the constant spawning of the pipes
        // time between pipes
        let pipeInterval = NSTimeInterval(2)
        let delay        = SKAction.waitForDuration(pipeInterval)

        // the action of spawning the pipe
        let spawn = SKAction.runBlock({
            self.spawnPipes()
        })

        // sequence of: spawn a pipe, then delay (until it gets called again)
        let pipeSequence = SKAction.sequence([spawn, delay])

        // do the above forever
        let pipeSpawn = SKAction.repeatActionForever(pipeSequence)

        // start the spawning!
        self.runAction(pipeSpawn)

        // finally, add the pipeNodes, which will hold all the pipe objects
        self.addChild(self.pipesNode)
    }

    // spawn a pair of pipes
    func spawnPipes()
    {
        // node for the up and down pipe to reside
        // create a column that the up/down pipes reside, and then set up hitboxes on each
        let pipeColumn = SKNode()

        // starting position just off-screen
        pipeColumn.position = CGPoint(x: self.frame.size.width, y: 0)

        // z-position
        pipeColumn.zPosition = self.pipeZpos

        // pipe y-axis placement
        // random number for randomness. UInt32 -> Double -> CGFloat for it to work with .position
        // random = big number, mod by pipeY for a reasonable number, add pipeY for even-ness
        let pipeY        = CGFloat(self.frame.size.height / 4)
        let random       = CGFloat(Double(arc4random()))
        let randomOffset = (random % pipeY) + pipeY

        // set up both pipes
        let topPipe    = self.generatePipe("top", randomOffset: randomOffset)
        let bottomPipe = self.generatePipe("bottom", randomOffset: randomOffset)

        // add pipes to column
        pipeColumn.addChild(topPipe)
        pipeColumn.addChild(bottomPipe)

        // offset to the right of the pipes, so you actually have to pass the pipes a little to register a score
        let scoreOffset:CGFloat = self.hero.size.width / 2

        // set up a contact area for the pipe gap, whose event trigger will increment the score
        let pipeGap                             = SKNode()
        pipeGap.position                        = CGPoint(x: topPipe.size.width, y: self.frame.size.height)
        pipeGap.physicsBody                     = SKPhysicsBody(rectangleOfSize: CGSize(width: 1.0, height: self.frame.size.height))
        pipeGap.physicsBody?.dynamic            = false
        pipeGap.physicsBody?.categoryBitMask    = self.pipeGapBitMask
        pipeGap.physicsBody?.contactTestBitMask = self.heroBitMask

        pipeColumn.addChild(pipeGap)


        pipeColumn.runAction(self.pipeNodeAnimation)
        self.pipesNode.addChild(pipeColumn)
    }


    // generate a pipe
    private func generatePipe(placement: String, randomOffset offset: CGFloat) -> SKSpriteNode
    {
        let texture: SKTexture = (placement == "top")
                                ? self.pipeDownTexture
                                : self.pipeUpTexture

        let pipe = SKSpriteNode(texture: texture)

        // shit images
        pipe.setScale(2.0)
        let position:CGPoint = (placement == "top")
                                ? CGPoint(x: 0, y: pipe.size.height + self.pipeGap + offset)
                                : CGPoint(x: 0, y: offset)

        // set top pipe to top of screen + pipe gap space + random offset
        pipe.position = position

        // pipes are rectangular anyway, so use a rectangle hitbox
        pipe.physicsBody = SKPhysicsBody(rectangleOfSize: pipe.size)

        // disable physics forces (gravity pulls the pipe down, lol)
        pipe.physicsBody?.dynamic = false

        // set category bitmask
        pipe.physicsBody?.categoryBitMask = self.pipeBitMask

        return pipe
    }

    // configure the animation of pipes across the screen
    private func setupPipeNodeAnimation() -> SKAction
    {
        // distance to move the pipe all the way to the left (frame width) + it's own size, so it's all off-screen
        let distanceToMove = CGFloat(self.frame.size.width + self.pipeUpTexture.size().width)

        // how fast it moves
        // set to 10 to match ground's 6.5 (texture width causes the difference)
        let pipeMoveTime = NSTimeInterval(7.50)

        // actions to move the pipe, and remove the pipe (after it goes off-screen)
        let movePipes   = SKAction.moveByX(-distanceToMove, y:0, duration:pipeMoveTime)
        let removePipes = SKAction.removeFromParent()

        // sequence of moving, removing pipes.
        return SKAction.sequence([movePipes, removePipes])
    }


    // game functions
    private func gameOver()
    {
        self.view?.scene!.paused = true
        self.addChild(self.retryButton)
        self.log("game over, idiot")
    }

    private func gameRestart()
    {
        // reset score
        self.score           = 0
        self.scoreLabel.text = "\(self.score)"

        // re-present the scene. i don't know if this is the best way to do this, though.
        let game       = GameScene(size: self.size)
        game.scaleMode = .AspectFill

        self.view?.presentScene(game)
        self.log("restarting game")
    }

    private func incrementScore()
    {
        self.score++
        self.scoreLabel.text = "\(self.score)"
        self.log("score: \(self.score)")
    }



    private func log(message: String)
    {
        #if DEBUG
            println(message)
        #endif
    }
}
