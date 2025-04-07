//
//  RFPSurface.swift
//  RCS
//
//  Created by Ray Septian Togi on 2024/4/8.
//

import RoomPlan

class RFPSurface {

    private let capturedSurface: CapturedRoom.Surface

    // MARK: - Computed properties

    var halfLength: CGFloat {
        return CGFloat(capturedSurface.dimensions.x)/2
    }

    public var pointA: Double {
        return Double(-halfLength)
    }

    public var pointB: Double {
        return Double(halfLength)
    }

    private var pointC: CGPoint {
        let pA = CGPoint(x: -halfLength,y: 0)
        let pB = CGPoint(x: halfLength,y: 0)
        return pB.rotateAround(point: pA, by: 0.25 * .pi)
    }
    
    
    private var _points: [(Double, Double, Double, Double)] = []

    var points: [(Double, Double, Double, Double)] {
        get {
            return _points
        }
        set {
            _points = newValue
        }
    }

    // MARK: - Init

    init(capturedSurface: CapturedRoom.Surface) {
        self.capturedSurface = capturedSurface

        // Set the surface's position using the transform matrix
//        let surfacePositionX = -CGFloat(capturedSurface.transform.position.x) * scalingFactor
//        let surfacePositionY = CGFloat(capturedSurface.transform.position.z) * scalingFactor
//        let position = CGPoint(x: surfacePositionX, y: surfacePositionY)
//
//        // Set the surface's zRotation using the transform matrix
//        let zRotation = -CGFloat(capturedSurface.transform.eulerAngles.z - capturedSurface.transform.eulerAngles.y)

        // Draw the right surface
        switch capturedSurface.category {
        case .door:
            drawDoor()
        case .opening:
            drawOpening()
        case .wall:
            drawWall()
        case .window:
            drawWindow()
        case .floor:
            ()
        @unknown default:
            drawWall()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Draw
    private func drawWall() {
        returnPoints(pointA: pointA, pointB: pointB)
    }

    private func drawDoor() {
//        let hideWallPath = returnPoints(from: pointA, to: pointB)
//        let doorPath = returnPoints(pointA: pointA, pointB: Float(pointC.x))
        returnPoints(pointA: pointA, pointB: Double(pointC.x))
//        // Hide the wall underneath the door
//        let hideWallShape = createShapeNode(from: hideWallPath)
//        hideWallShape.strokeColor = floorPlanBackgroundColor
//        hideWallShape.lineWidth = hideSurfaceWith
//        hideWallShape.zPosition = hideSurfaceZPosition
//
//        // The door itself
//        let doorShape = createShapeNode(from: doorPath)
//        doorShape.lineCap = .square
//        doorShape.zPosition = doorZPosition
//
//        // The door's arc
//        let doorArcPath = CGMutablePath()
//        doorArcPath.addArc(
//            center: pointA,
//            radius: halfLength * 2,
//            startAngle: 0.25 * .pi,
//            endAngle: 0,
//            clockwise: true
//        )
//
//        // Create a dashed path
//        let dashPattern: [CGFloat] = [24.0, 8.0]
//        let dashedArcPath = doorArcPath.copy(dashingWithPhase: 1, lengths: dashPattern)
//
//        let doorArcShape = createShapeNode(from: dashedArcPath)
//        doorArcShape.lineWidth = doorArcWidth
//        doorArcShape.zPosition = doorArcZPosition

//        addChild(hideWallShape)
//        addChild(doorShape)
//        addChild(doorArcShape)
    }

    private func drawOpening() { // DO NOTHING ?
//        let openingPath = returnPoints(pointA: pointA, pointB: pointB)
//
//        // Hide the wall underneath the opening
//        let hideWallShape = createShapeNode(from: openingPath)
//        hideWallShape.strokeColor = floorPlanBackgroundColor
//        hideWallShape.lineWidth = hideSurfaceWith
//        hideWallShape.zPosition = hideSurfaceZPosition

//        addChild(hideWallShape)
    }



    private func drawWindow() {
//        let windowPath = returnPoints(pointA: pointA, pointB: pointB)
        returnPoints(pointA: pointA, pointB: pointB)
//        // Hide the wall underneath the window
//        let hideWallShape = createShapeNode(from: windowPath)
//        hideWallShape.strokeColor = floorPlanBackgroundColor
//        hideWallShape.lineWidth = hideSurfaceWith
//        hideWallShape.zPosition = hideSurfaceZPosition
//
//        // The window itself
//        let windowShape = createShapeNode(from: windowPath)a
//        windowShape.lineWidth = windowWidth
//        windowShape.zPosition = windowZPosition

//        addChild(hideWallShape)
//        addChild(windowShape)
    }

    // MARK: - Helper functions

    func returnPoints(pointA: Double, pointB: Double){
        let surfacePositionX = Double(capturedSurface.transform.position.x)
        let surfacePositionY = Double(capturedSurface.transform.position.z)
        
        let yRot = capturedSurface.transform.eulerAngles.y // radians
        let zRot = capturedSurface.transform.eulerAngles.z // zRot = xRot -> causes gimbal lock problem
        var angle = 0.0
//         Gimbal lock problem...
        if (zRot > 3.14){
            angle = Double(-yRot)
        }
        else{
            angle = Double(yRot)
        }
        print(capturedSurface.transform.eulerAngles)
        
        // Rotation is x' = xcos - ysin ; y' = xsin + ycos
        let x1 = pointA*cos(angle) + surfacePositionX
        let y1 = pointA*sin(angle) + surfacePositionY
        let x2 = pointB*cos(angle) + surfacePositionX
        let y2 = pointB*sin(angle) + surfacePositionY
        points.append((x1,y1,x2,y2))
    }
}
