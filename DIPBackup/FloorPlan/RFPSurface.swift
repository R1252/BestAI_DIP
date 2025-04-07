//
//  RFPSurface.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/4/8.
//

import RoomPlan
import simd

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

    init(capturedSurface: CapturedRoom.Surface, rotAngle: Double) {
        self.capturedSurface = capturedSurface
        let endPoints = calculateWallEnds(transform: capturedSurface.transform, xDim: capturedSurface.dimensions.x)
        
        let x1 = Double(endPoints.first!.x)
        let y1 = Double(endPoints.first!.y)
        let x2 = Double(endPoints.last!.x)
        let y2 = Double(endPoints.last!.y)
        
        // Draw the right surface
        switch capturedSurface.category {
        case .wall:
            // draw inside line
            points.append((x1,y1,x2,y2))
        case .window:
            // draw middle lines
            points.append((x1,y1,x2,y2))
            let pointO = CGPoint(x: 1/2*(x2+x1), y: 1/2*(y2+y1))
            let point1 = CGPoint(x: x1, y: y1).rotateAround(point: pointO, by: .pi/2)
            let point2 = CGPoint(x: x2, y: y2).rotateAround(point: pointO, by: .pi/2)
            
            let dx = point2.x - point1.x
            let dy = point2.y - point1.y
            let vLength = sqrt(dx*dx+dy*dy)
            
            let unit_dx = dx / vLength
            let unit_dy = dy / vLength
            
            let x1_1 = pointO.x + 0.2*unit_dx
            let y1_1 = pointO.y + 0.2*unit_dy
            let x2_1 = pointO.x - 0.2*unit_dx
            let y2_1 = pointO.y - 0.2*unit_dy
            
            points.append((x1_1,y1_1,x2_1,y2_1))
//            points.append((point1.x,point1.y,point2.x,point2.y))
            
            // draw scaled windows
//            points.append((x1*wScale,y1*wScale,x2*wScale,y2*wScale))
//            points.append((x1*wScale_2,y1*wScale_2,x2*wScale_2,y2*wScale_2))
            
        case .door:
            // create perpendicular line
            let pointC = CGPoint(x: x2, y: y2).rotateAround(point: CGPoint(x: x1, y: y1), by: -.pi/2)
            points.append((x1,y1,pointC.x,pointC.y))
        case .opening:
            ()
        case .floor:
            ()
        @unknown default:
            ()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
