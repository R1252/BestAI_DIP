//
//  SKFPSurface.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/10/11.
//

import RoomPlan
import SpriteKit

class FloorPlanSurface: SKNode {
    private let capturedSurface: CapturedRoom.Surface
    private var door_index = 0
    private var doors: [String:Bool]

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(capturedSurface: CapturedRoom.Surface, doorIndex: Int, room: RoomScanned) {
        self.capturedSurface = capturedSurface
        self.door_index = doorIndex
        self.doors = room.doors
        
        super.init()
        // RAY EDIT
        let surfacePositionX = /*SKFPFrameSize.width -*/ -CGFloat(capturedSurface.transform.position.x) * scalingFactor
        let surfacePositionY = CGFloat(capturedSurface.transform.position.z) * scalingFactor
        self.position = CGPoint(x: surfacePositionX, y: surfacePositionY)
        self.zRotation = -CGFloat(capturedSurface.transform.eulerAngles.z - capturedSurface.transform.eulerAngles.y)
        
        
        switch capturedSurface.category {
        case .opening:
            drawOpening()
        case .wall:
            drawWall()
        case .window:
            drawWindow()
        case .door:
            drawDoor()
//            var draw = true
//            for door in doors {
//                if capturedSurface.dimensions.x/2 == -door.dimensions.x/2 {
//                    draw = false
//                    print("Debug - duplicates found")
//                }
//            }
//            if draw {
//                doors.append(capturedSurface)
//                drawDoor()
//            }
        default:
            drawWall()
        }
    }
    
    private var halfLength: CGFloat {
        return CGFloat(capturedSurface.dimensions.x) * scalingFactor / 2
    }
        
    private var pointA: CGPoint {
        return CGPoint(x: -halfLength, y: 0)
    }
        
    private var pointB: CGPoint {
        return CGPoint(x: halfLength, y: 0)
    }
    
    private var pointC: CGPoint {
        return pointB.rotateAround(point: pointA, by: 0.25 * .pi)
    }
    
    private func createPath(from pointA: CGPoint, to pointB: CGPoint) -> CGMutablePath {
        let path = CGMutablePath()
        path.move(to: pointA)
        path.addLine(to: pointB)
            
        return path
    }
    
    private func createShapeNode(from path: CGPath, surfaceWidth: CGFloat) -> SKShapeNode {
        let shapeNode = SKShapeNode(path: path)
        shapeNode.strokeColor = floorPlanSurfaceColor
        shapeNode.lineWidth = surfaceWidth
            
        return shapeNode
    }
    
    private func drawWall() {
        let wallPath = createPath(from: pointA, to: pointB)
        let wallShape = createShapeNode(from: wallPath, surfaceWidth: surfaceWidth)
        wallShape.lineCap = .square

        addChild(wallShape)
    }
    
    private func drawOpening() {
        let openingPath = createPath(from: pointA, to: pointB)
            
        // Hide the wall underneath the opening
        let hideWallShape = createShapeNode(from: openingPath, surfaceWidth: surfaceWidth)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWidth
        hideWallShape.zPosition = hideSurfaceZPosition
            
        addChild(hideWallShape)
    }
    
    private func drawWindow() {
        let windowPath = createPath(from: pointA, to: pointB)
            
        // Hide the wall underneath the window
        let hideWallShape = createShapeNode(from: windowPath, surfaceWidth: surfaceWidth)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWidth
        hideWallShape.zPosition = hideSurfaceZPosition
            
        // The window itself
        let windowShape = createShapeNode(from: windowPath, surfaceWidth: surfaceWidth)
        windowShape.lineWidth = windowWidth
        windowShape.zPosition = windowZPosition
            
        addChild(hideWallShape)
        addChild(windowShape)
    }

    private func drawDoor() {
        self.name = "door_\(door_index)"
        let bool = doors[name!]!
        let hideWallPath = createPath(from: pointA, to: pointB)
        let doorPath = createPath(from: pointA, to: pointC)

        // Hide the wall underneath the door
        let hideWallShape = createShapeNode(from: hideWallPath, surfaceWidth: surfaceWidth)
        hideWallShape.strokeColor = floorPlanBackgroundColor
        hideWallShape.lineWidth = hideSurfaceWidth
        hideWallShape.zPosition = hideSurfaceZPosition
            
        // The door itself
        let doorOpenShape = createShapeNode(from: doorPath, surfaceWidth: surfaceWidth)
        doorOpenShape.lineCap = .square
        doorOpenShape.zPosition = doorZPosition
        doorOpenShape.name = "doorOpenShape"
        doorOpenShape.isHidden = !bool
        
        let doorArcPath = CGMutablePath()
        doorArcPath.addArc(
            center: pointA,
            radius: halfLength * 2,
            startAngle: 0.25 * .pi,
            endAngle: 0,
            clockwise: true
        )
                
        // Create a dashed path
        let dashPattern: [CGFloat] = [24.0, 8.0]
        let dashedArcPath = doorArcPath.copy(dashingWithPhase: 1, lengths: dashPattern)

        let doorADIPhape = createShapeNode(from: dashedArcPath, surfaceWidth: surfaceWidth)
        doorADIPhape.lineWidth = doorArcWidth
        doorADIPhape.zPosition = doorArcZPosition
        doorADIPhape.name = "doorADIPhape"
        doorADIPhape.isHidden = !bool
        
        let pointA_1 = CGPoint(x: -halfLength, y: -surfaceWidth/4)
        let pointA_2 = CGPoint(x: halfLength/4, y: -surfaceWidth/4)
        let pointB_1 = CGPoint(x: halfLength, y: surfaceWidth/4)
        let pointB_2 = CGPoint(x: -halfLength/4, y: surfaceWidth/4)
        
        let doorSlidingPathA = createPath(from: pointA_1, to: pointA_2)
        let doorSlidingShapeA = createShapeNode(from: doorSlidingPathA, surfaceWidth: surfaceWidth/2)
        doorSlidingShapeA.lineWidth = windowWidth
        doorSlidingShapeA.zPosition = doorZPosition
        doorSlidingShapeA.name = "doorSlidingShapeA"
        doorSlidingShapeA.isHidden = bool
        
        let doorSlidingPathB = createPath(from: pointB_1, to: pointB_2)
        let doorSlidingShapeB = createShapeNode(from: doorSlidingPathB, surfaceWidth: surfaceWidth/2)
        doorSlidingShapeB.lineWidth = windowWidth
        doorSlidingShapeB.zPosition = doorZPosition
        doorSlidingShapeB.name = "doorSlidingShapeB"
        doorSlidingShapeB.isHidden = bool
        
        self.isUserInteractionEnabled = true
        
        addChild(hideWallShape)
        addChild(doorOpenShape)
        addChild(doorADIPhape)
        addChild(doorSlidingShapeA)
        addChild(doorSlidingShapeB)
    }
}
