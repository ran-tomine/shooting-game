//
//  GameScene.swift
//  shooting-game
//
//  Created by 遠峰嵐 on 2023/07/28.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene {
    let motionManager = CMMotionManager()
    var accelaration: CGFloat = 0.0
    
    var earth: SKSpriteNode!
    var spaceship: SKSpriteNode!
    
    override func didMove(to view: SKView) {
        self.earth = SKSpriteNode(imageNamed: "earth")
        self.earth.xScale = 1.5
        self.earth.yScale = 0.3
        self.earth.position = CGPoint(x: 0, y: -frame.height / 2)
        self.earth.zPosition = -1.0
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
    }

    override func didSimulatePhysics() {
        let nextPosition = self.spaceship.position.x + self.accelaration * 50
        if nextPosition > frame.width / 2 - 30 { return }
        if nextPosition < -frame.width / 2 + 30 { return }
        self.spaceship.position.x = nextPosition
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
