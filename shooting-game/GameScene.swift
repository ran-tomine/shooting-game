//
//  GameScene.swift
//  shooting-game
//
//  Created by 遠峰嵐 on 2023/07/28.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var gameVC: GameViewController!
    
    let motionManager = CMMotionManager()
    var accelaration: CGFloat = 0.0
    
    var timer: Timer?
    var timerForAsteroud: Timer?
    var asteroudDuration: TimeInterval = 6.0 {
        didSet {
            if asteroudDuration < 2.0 {
                timerForAsteroud?.invalidate()
            }
        }
    }
    var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    let spaceshipCategory: UInt32 = 0b0001
    let missileCategory: UInt32 = 0b0010
    let asteroidCategory: UInt32 = 0b0100
    let earthCategory: UInt32 = 0b1000

    
    var earth: SKSpriteNode!
    var spaceship: SKSpriteNode!
    var hearts: [SKSpriteNode] = []
    var scoreLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        self.earth = SKSpriteNode(imageNamed: "earth")
        self.earth.xScale = 1.5
        self.earth.yScale = 0.3
        self.earth.position = CGPoint(x: 0, y: -frame.height / 2)
        self.earth.zPosition = -1.0
        self.earth.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: frame.width, height: 100))
        self.earth.physicsBody?.categoryBitMask = earthCategory
        self.earth.physicsBody?.contactTestBitMask = asteroidCategory
        self.earth.physicsBody?.collisionBitMask = 0
        addChild(self.earth)
        
        self.spaceship = SKSpriteNode(imageNamed: "spaceship")
        self.spaceship.scale(to: CGSize(width: frame.width / 5, height: frame.width / 5))
        self.spaceship.position = CGPoint(x: 0, y: self.earth.frame.maxY + 50)
        addChild(self.spaceship)
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, _) in
            guard let data = data else { return }
            let a = data.acceleration
            self.accelaration = CGFloat(a.x) * 0.75 + self.accelaration * 0.25
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.addAsteroid()
        })
        for i in 1...5 {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.position = CGPoint(x: -frame.width / 2 + heart.frame.height * CGFloat(i), y: frame.height / 2 - heart.frame.height)
            addChild(heart)
            hearts.append(heart)
        }
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontName = "Papyrus"
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: -frame.width / 2 + scoreLabel.frame.width / 2 + 50, y: frame.height / 2 - scoreLabel.frame.height * 5)
        addChild(scoreLabel)
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        let bestScoreLabel = SKLabelNode(text: "Best Score: \(bestScore)")
        bestScoreLabel.fontName = "Papyrus"
        bestScoreLabel.fontSize = 30
        bestScoreLabel.position = scoreLabel.position.applying(CGAffineTransform(translationX: 0, y: -bestScoreLabel.frame.height * 1.5))
        addChild(bestScoreLabel)
        timerForAsteroud = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { _ in
            self.asteroudDuration -= 0.5
        })
    }

    override func didSimulatePhysics() {
        let nextPosition = self.spaceship.position.x + self.accelaration * 50
        if nextPosition > frame.width / 2 - 30 { return }
        if nextPosition < -frame.width / 2 + 30 { return }
        self.spaceship.position.x = nextPosition
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPaused { return }
        let missile = SKSpriteNode(imageNamed: "missile")
        missile.position = CGPoint(x: self.spaceship.position.x, y: self.spaceship.position.y + 50)
        missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.frame.height / 2)
        missile.physicsBody?.categoryBitMask = missileCategory
        missile.physicsBody?.contactTestBitMask = asteroidCategory
        missile.physicsBody?.collisionBitMask = 0
        addChild(missile)

        let moveToTop = SKAction.moveTo(y: frame.height + 10, duration: 0.3)
        let remove = SKAction.removeFromParent()
        missile.run(SKAction.sequence([moveToTop, remove]))
    }
    func addAsteroid() {
        let names = ["asteroid1", "asteroid2", "asteroid3"]
        let index = Int(arc4random_uniform(UInt32(names.count)))
        let name = names[index]
        let asteroid = SKSpriteNode(imageNamed: name)
        let random = CGFloat(arc4random_uniform(UINT32_MAX)) / CGFloat(UINT32_MAX)
        let positionX = frame.width * (random - 0.5)
        asteroid.position = CGPoint(x: positionX, y: frame.height / 2 + asteroid.frame.height)
        asteroid.scale(to: CGSize(width: 70, height: 70))
        asteroid.physicsBody = SKPhysicsBody(circleOfRadius: asteroid.frame.width)
        asteroid.physicsBody?.categoryBitMask = asteroidCategory
        asteroid.physicsBody?.contactTestBitMask = missileCategory + spaceshipCategory + earthCategory
        asteroid.physicsBody?.collisionBitMask = 0
        addChild(asteroid)

        let move = SKAction.moveTo(y: -frame.height / 2 - asteroid.frame.height, duration: asteroudDuration)
        let remove = SKAction.removeFromParent()
        asteroid.run(SKAction.sequence([move, remove]))
    }
    func didBegin(_ contact: SKPhysicsContact) {
        var asteroid: SKPhysicsBody
        var target: SKPhysicsBody

        if contact.bodyA.categoryBitMask == asteroidCategory {
            asteroid = contact.bodyA
            target = contact.bodyB
        } else {
            asteroid = contact.bodyB
            target = contact.bodyA
        }

        guard let asteroidNode = asteroid.node else { return }
        guard let targetNode = target.node else { return }
        guard let explosion = SKEmitterNode(fileNamed: "Explosion") else { return }
        explosion.position = asteroidNode.position
        addChild(explosion)

        asteroidNode.removeFromParent()
        if target.categoryBitMask == missileCategory {
            targetNode.removeFromParent()
        }

        self.run(SKAction.wait(forDuration: 1.0)) {
            explosion.removeFromParent()
        }
        if target.categoryBitMask == spaceshipCategory || target.categoryBitMask == earthCategory {
            guard let heart = hearts.last else { return }
            heart.removeFromParent()
            hearts.removeLast()
            if hearts.isEmpty {
                gameOver()
            }
            score += 5
        }
    }
    func gameOver() {
        isPaused = true
        timer?.invalidate()
        let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
        if score > bestScore {
            UserDefaults.standard.set(score, forKey: "bestScore")
        }
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            self.gameVC.dismiss(animated: true, completion: nil)
        }
    }

}
