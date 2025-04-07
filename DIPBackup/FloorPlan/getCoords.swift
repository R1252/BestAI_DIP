//
//  getCoords.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/5/9.
//

import ARKit

func getCoords(anchor: ARAnchor, camAnchors: ARAnchor) -> [CGPoint]{
    var coords = [CGPoint]()
    
    let x2 = Double(camAnchors.transform.columns.3.x)
    let y2 = Double(camAnchors.transform.columns.3.z)

    // wall point
    var x1 = Double(anchor.transform.position.x)
    var y1 = Double(anchor.transform.position.z)
    let P0 = CGPoint(x: x1,y: y1) // Defect position at wall
    
    // Calculate the direction vector from (x2, y2) to (x1, y1)
    let dx = x1 - x2
    let dy = y1 - y2

    // Calculate the length of the direction vector
    let length = sqrt(dx*dx+dy*dy)

    // Normalize the direction vector to get the unit vector
    let unit_dx = dx / length
    let unit_dy = dy / length

    // Calculate the coordinates of the endpoint of the line segment
    x1 = x2 + 0.25 * unit_dx
    y1 = y2 + 0.25 * unit_dy
    
    // y is negative to flip
    let P1 = CGPoint(x: x1 * 4, y: y1 * 4) // P1 = Tip of arrow calculated from camAnchor position
    let P2 = CGPoint(x: x2 * 4, y: y2 * 4) // P2 = camAnchor position
    
    let x3 = x1 - 0.1 * unit_dx
    let y3 = y1 - 0.1 * unit_dy
    
    let P3 = CGPoint(x: x3 * 4, y: y3 * 4)
    let P3_1 = P3.rotateAround(point: P1, by: .pi/6) // ArrowHead
    let P3_2 = P3.rotateAround(point: P1, by: -.pi/6) // ArrowHead
     
    coords.append(P1) // P1
    coords.append(P2) // P2
    coords.append(P3_1) //P3_1
    coords.append(P3_2) //P3_2
    coords.append(P0)
    
    return coords
}
