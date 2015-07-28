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
    }


    func setupHero() -> SKSpriteNode
    {
        let heroTexture = SKTexture(imageNamed: "bowst")
        heroTexture.filteringMode = SKTextureFilteringMode.Nearest

        let hero = SKSpriteNode(texture: heroTexture)

        // set the scale here so when i call hero.size later it works
        // hero.setScale(0.75)
        hero.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)

        hero.physicsBody = SKPhysicsBody(rectangleOfSize: hero.size)
        hero.physicsBody?.dynamic = true
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



    func setupGround()
    {
        let groundTex = SKTexture(imageNamed: "land")

        let groundTexSize   = groundTex.size()
        let groundTexWidth  = groundTexSize.width
        let groundTexHeight = groundTexSize.height

        let scale:CGFloat = CGFloat(2.0)


        println(groundTexWidth) // 336
        println(groundTexWidth * 2.0) // 672
        println(0.02 * groundTexWidth * 2.0) // 13.44
        println(2.0 * self.frame.width / (groundTexWidth * 2.0)) // 3.0476...

        // lower number = faster interval (duh)
        let groundMoveTime = NSTimeInterval(10)

        // move ground to the left (negative x-axis) on a timer, defined above
        let moveGroundSprite = SKAction.moveByX(-groundTexWidth * scale, y: 0, duration: groundMoveTime)

        // reset ground so it looks like its continuous. works cause bg is the same in and out
        let resetGroundSprite = SKAction.moveByX(groundTexWidth * scale, y: 0, duration: 0.0)

        //
        let moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        groundTex.filteringMode = SKTextureFilteringMode.Nearest

        // add enough sprites to the scrolling node so you dont run out
        for var i:CGFloat = 0; i <= scale; i++
        {
            let sprite = SKSpriteNode(texture: groundTex)
            sprite.setScale(scale)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2)
            sprite.runAction(moveGroundSpritesForever)
            self.scrollNode.addChild(sprite)
        }


        self.groundNode.position = CGPoint(x: 0, y: groundTexHeight)
        self.groundNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: self.frame.size.width, height: groundTexHeight * 2.0))
        self.groundNode.physicsBody?.dynamic = false
        self.groundNode.physicsBody?.categoryBitMask = self.levelCat

        // scrollNode and groundNode are entirely separate things that just happen to reside in the same coordinate-space (for obv reasons)
        self.addChild(self.groundNode)
        self.addChild(self.scrollNode)
    }


    // touch me
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        // because it's falling, it has velocity. change it to 0
        self.hero.physicsBody?.velocity = CGVector(dx: 0, dy: 0)

        // then apply a force upwards
        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 150))
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
