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

    let skyColor = SKColor(red: 0, green: 191, blue: 255, alpha: 1)

    // collisions and such on the heros physicsBody use bitmasks to determine stuff
    // so by declaring each type of category i want as ints bit shifted in increments, i can
    // determine which objects are involved in a collision
    // each bitmask is defaulted to either 0x00000000 or 0xFFFFFFFF, obv 32bits
    // so i can have a total of 32 different categories
    let heroCat: UInt32  = 1 << 0 // 1
    let pipeCat: UInt32  = 1 << 1 // 2
    let levelCat: UInt32 = 1 << 2 // 4
    let scoreCat: UInt32 = 1 << 3 // 8

    var hero: SKSpriteNode!

    var scrollNode = SKNode()
    var groundNode = SKNode()

    // setup
    override func didMoveToView(view: SKView) {
        self.backgroundColor = self.skyColor

        // set world physics
        // x, positive = right, negative = left
        // y, positive = up, negative = down
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -8)
        self.physicsWorld.contactDelegate = self

        self.hero = self.setupHero()
        self.setupGround()
        self.setupSkyLine()
    }


    func setupHero() -> SKSpriteNode
    {
        let heroTexture = SKTexture(imageNamed: "dickbutt")
        heroTexture.filteringMode = SKTextureFilteringMode.Nearest

        let hero = SKSpriteNode(texture: heroTexture)
        hero.position = CGPoint(x: self.frame.size.width * 0.33, y: self.frame.size.height * 0.75)

        hero.physicsBody = SKPhysicsBody(rectangleOfSize: hero.size)
        hero.physicsBody?.allowsRotation = false

        // set this value so when collission happens, i can test the "category" property to determine
        // what to do, depending on what object gets hit, defined below
        hero.physicsBody?.categoryBitMask = self.heroCat

        // determines which objects hero is capable of colliding with
        hero.physicsBody?.collisionBitMask = self.pipeCat | self.levelCat

        // determines which objects send an event when collided with
        hero.physicsBody?.contactTestBitMask = self.pipeCat | self.levelCat

        // add to scene
        self.addChild(hero)
        return hero
    }



    func setupSkyLine()
    {
        let skyTex = SKTexture(imageNamed: "sky")
        skyTex.filteringMode = SKTextureFilteringMode.Nearest

        // only need this for it's dimensions
        let groundTex = SKTexture(imageNamed: "land")
        let groundHeight = groundTex.size().height

        let skyTexSize   = skyTex.size()
        let skyTexWidth  = skyTexSize.width
        let skyTexHeight = skyTexSize.height

        self.log("setupSkyLine: skyTexSize: \(skyTexSize)")

        let scale:CGFloat = CGFloat(2.0)
        let skyMoveTime = NSTimeInterval(40)

        let moveSkySprite = SKAction.moveByX(-skyTexWidth * scale, y: 0, duration: skyMoveTime)

        let resetSkySprite = SKAction.moveByX(skyTexWidth * scale, y: 0, duration: 0.0)

        let moveSkySpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkySprite, resetSkySprite]))

        for var i:CGFloat = 0; i <= scale; i++
        {
            // sprite.size = skyTex (336 x 112 for that image)
            let sprite = SKSpriteNode(texture: skyTex)

            // scale sprite.size to fill more screen
            sprite.setScale(scale)
            self.log("setupSkyLine: sprite position: \(i * sprite.size.width)")

            sprite.zPosition = -20 // -20, find out what the others are

            // i * width to stagger right, height = sprite.height * scale - ground.height
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height * scale - groundHeight)

            sprite.runAction(moveSkySpritesForever)
            self.scrollNode.addChild(sprite)
        }
    }



    func setupGround()
    {
        let groundTex = SKTexture(imageNamed: "land")
        groundTex.filteringMode = SKTextureFilteringMode.Nearest

        let groundTexSize   = groundTex.size()
        let groundTexWidth  = groundTexSize.width
        let groundTexHeight = groundTexSize.height

        self.log("setupGround: groundTexSize: \(groundTexSize)")

        // scale up groundTex cause its low-res lol
        // if they were full-res i wouldn't have to
        // this is used when adding ground texture sprites to the scrollNode
        let scale:CGFloat = CGFloat(2.0)

        // define animations!
        // lower number = faster interval (duh)
        let groundMoveTime = NSTimeInterval(10)

        // move ground to the left (negative x-axis) on a timer, defined above
        let moveGroundSprite = SKAction.moveByX(-groundTexWidth * scale, y: 0, duration: groundMoveTime)

        // reset ground so it looks like its continuous
        let resetGroundSprite = SKAction.moveByX(groundTexWidth * scale, y: 0, duration: 0.0)

        // this is the "main" action that gets set on the sprite, that is a sequence of the above 2 actions
        let moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))

        // add enough sprites to the scrolling node so you dont run out before it resets
        // i < 2.0 * self.frame.size.width / (groundTexWidth * 2)
        // if scale = 2, above = 3.04, below would iterate 3 times, could be coincidence
        for var i:CGFloat = 0; i <= scale; i++
        {
            // sprite.size = groundTex.size (336 x 112 for that image)
            let sprite = SKSpriteNode(texture: groundTex)

            // scale sprite.size to fill more screen
            sprite.setScale(scale)
            self.log("setupGround: sprite position: \(i * sprite.size.width)")

            // i * width to stagger right, height / 2 because scale
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / scale)

            sprite.runAction(moveGroundSpritesForever)
            self.scrollNode.addChild(sprite)
        }

        // groundNode is the physics body that gets collided with, groundTexHeight = sprite.height/2 (cause of scale)
        self.groundNode.position = CGPoint(x: 0, y: groundTexHeight)
        self.groundNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: self.frame.size.width, height: groundTexHeight * scale))
        self.groundNode.physicsBody?.dynamic = false
        self.groundNode.physicsBody?.categoryBitMask = self.levelCat

        // scrollNode and groundNode are entirely separate things that just happen to reside in the same coordinate-space (for obv reasons)
        self.addChild(self.groundNode)
        self.addChild(self.scrollNode)
    }



    private func log(message: String)
    {
        #if DEBUG
            println(message)
        #endif
    }


    // touch me
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        // because it's falling, it has velocity. change it to 0
        self.hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)

        // then apply a force upwards
        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50))
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
