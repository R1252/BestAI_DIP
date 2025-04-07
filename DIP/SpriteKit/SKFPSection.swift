//
//  SKFPSection.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/11/15.
//

import RoomPlan
import SpriteKit

class FloorPlanSection: SKNode {
    private let section: CapturedRoom.Section
       init(section: CapturedRoom.Section) {
           self.section = section
           super.init()
           // Set the object's position using the transform matrix
           let sectionPositionX = -CGFloat(section.center.x) * scalingFactor
           let sectionPositionY = CGFloat(section.center.z) * scalingFactor
           self.position = CGPoint(x: sectionPositionX, y: sectionPositionY)
           drawSection()
       }
       
       required init?(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    
    private func drawSection() {
        // add text label
        let text = SKLabelNode(text: section.label.rawValue)
        text.zRotation += CGFloat(SKFPAngle)
        text.fontName = "Helvetica Bold"
        text.fontColor = .black
        text.fontSize = 24
        text.position = position
        addChild(text)
    }
}
