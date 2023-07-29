//
//  GameScene.swift
//  shooting-game
//
//  Created by 遠峰嵐 on 2023/07/28.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    var earth: SKSpriteNode!
    override func didMove(to view: SKView) {
        self.earth = SKSpriteNode(imageNamed: "earth")
        self.earth.xScale = 1.5
        self.earth.yScale = 0.3
        self.earth.position = CGPoint(x: 0, y: -frame.height / 2)
        self.earth.zPosition = -1.0
        addChild(self.earth)
    }
}
