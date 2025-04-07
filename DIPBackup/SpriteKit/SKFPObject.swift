//
//  SKFPObject.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/10/11.
//

import RoomPlan
import SpriteKit

class FloorPlanObject: SKNode {
    private let capturedObject: CapturedRoom.Object
       
       init(capturedObject: CapturedRoom.Object) {
           self.capturedObject = capturedObject
           super.init()
           // Set the object's position using the transform matrix
           let objectPositionX = -CGFloat(capturedObject.transform.position.x) * scalingFactor
           let objectPositionY = CGFloat(capturedObject.transform.position.z) * scalingFactor
           self.position = CGPoint(x: objectPositionX, y: objectPositionY)
           self.name = "furniture"
           
           // Set the object's zRotation using the transform matrix
           self.zRotation = -CGFloat(capturedObject.transform.eulerAngles.z - capturedObject.transform.eulerAngles.y)
           drawObject()
       }
       
       required init?(coder aDecoder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }
    
    private func drawObject() {
        // Calculate the object's dimensions
        let objectWidth = CGFloat(capturedObject.dimensions.x) * scalingFactor
        let objectHeight = CGFloat(capturedObject.dimensions.z) * scalingFactor
            
        // Create the object's rectangle
        let objectRect = CGRect(
            x: -objectWidth / 2,
            y: -objectHeight / 2,
            width: objectWidth,
            height: objectHeight
        )
            
        // A shape to fill the object
        let objectShape = SKShapeNode(rect: objectRect)
        objectShape.strokeColor = .clear
        objectShape.fillColor = floorPlanSurfaceColor.withAlphaComponent(0.3)
        objectShape.zPosition = objectZPosition
        
        // And another shape for the outline
        let objectOutlineShape = SKShapeNode(rect: objectRect)
        objectOutlineShape.strokeColor = floorPlanSurfaceColor
        objectOutlineShape.lineWidth = objectOutlineWidth
        objectOutlineShape.lineJoin = .miter
        objectOutlineShape.zPosition = objectOutlineZPosition
            
        // Add both shapes to the node
        addChild(objectShape)
        addChild(objectOutlineShape)
    }
}
