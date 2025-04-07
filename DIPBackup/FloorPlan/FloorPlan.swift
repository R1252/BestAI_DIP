//
//  FloorPlan.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/4/8.
//

import RoomPlan
import ARKit

class FloorPlan {
    // Surfaces and objects from our scan result
    private let surfaces: [CapturedRoom.Surface]
    private let doors : [CapturedRoom.Surface]
    private let defectAnchors: [ARAnchor]?
    private let camAnchors: [ARAnchor]?
    var destinationURL : URL?
    
    var dxfContent = "0\nSECTION\n2\nHEADER\n0\nENDSEC\n0\nSECTION\n2\nTABLES\n0\nENDSEC\n0\nSECTION\n2\nBLOCKS\n0\nENDSEC\n0\nSECTION\n2\nENTITIES\n"
    
    // MARK: - Init
    init(structure: CapturedStructure, defectAnchors: [ARAnchor]?, camAnchors: [ARAnchor]?, folderURL: URL) {
        self.surfaces = structure.openings + structure.walls + structure.windows
        self.doors = structure.doors
        self.defectAnchors = defectAnchors
        self.camAnchors = camAnchors
        self.destinationURL = folderURL.appending(path: "Room.dxf")
        
        //        let rotAngle = Double(capturedRoom.doors.first!.transform.eulerAngles.y)
        let rotAngle = 0.0
        
        drawSurfaces(rotAngle: rotAngle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Draw
    private func drawSurfaces(rotAngle: Double) {
        for surface in surfaces {
            let surfaceNode = RFPSurface(capturedSurface: surface, rotAngle: rotAngle)
            for (x1,y1,x2,y2) in surfaceNode.points {
                dxfContent += "0\nLINE\n8\n0\n"
                dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",x1, y1, x2, y2)
                // to implement : rotate angle according to floor/door
            }
        }
        
        for door in doors {
//            print("Debug - doors count", doors.count)
            let doorNode = RFPSurface(capturedSurface: door, rotAngle: rotAngle)
            let x1 = doorNode.points[0].0
            let y1 = doorNode.points[0].1
            let x2 = doorNode.points[0].2
            let y2 = doorNode.points[0].3
            
            // Line for door
            dxfContent += "0\nLINE\n8\n0\n"
            dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",x1, y1, x2, y2)
            
            // Arc for door
            dxfContent += "0\nARC\n8\n0\n"
            let doorAngle = atan2(y2-y1,x2-x1)*180/3.14
            let doorLength = simd_distance(simd_double2(x1,y1),simd_double2(x2,y2))
            
            dxfContent += String(format: "10\n%.3f\n20\n%.3f\n40\n%.3f\n50\n%.3f\n51\n%.3f\n",x1, y1, doorLength, doorAngle, doorAngle+90)
        }
        
        if let camAnchors = camAnchors {
            if var anchors = defectAnchors {
                var similarAnchorIndices: [Int] = []
                
                // Check similarity with other anchors
                for (index,anchor) in anchors.enumerated() {
                    let tolerance = Float(0.01)
                    let x1 = anchor.transform.columns.3.x
                    let y1 = anchor.transform.columns.3.z
                    
                    for otherIndex in 0..<anchors.underestimatedCount{
                        if otherIndex != index && !similarAnchorIndices.contains(index){
                            let otherAnchor = anchors[otherIndex]
                            let otherX1 = otherAnchor.transform.position.x
                            let otherY1 = otherAnchor.transform.position.z
                            
                            // Compare x1 and y1 values
                            if abs(x1 - otherX1) < tolerance && abs(y1 - otherY1) < tolerance || otherX1 == 0.0 && otherY1 == 0.0 {
                                // anchors.remove(at: otherIndex)
                                similarAnchorIndices.append(otherIndex)
                            }
                        }
                    }
                }
                
                // Draw unique anchors
                for (index,anchor) in anchors.enumerated(){
                    if !similarAnchorIndices.contains(index){
                        let coords = getCoords(anchor: anchor, camAnchors: camAnchors[index])
                        // Line from cam to detect
                        dxfContent += "0\nLINE\n8\n0\n"
                        dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",coords[0].x, coords[0].y, coords[1].x, coords[1].y)
                        
                        // Arrows
                        dxfContent += "0\nLINE\n8\n0\n"
                        dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",coords[0].x, coords[0].y, coords[2].x, coords[2].y)
                        
                        dxfContent += "0\nLINE\n8\n0\n"
                        dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",coords[0].x, coords[0].y, coords[3].x, coords[3].y)
                        
                        // Label
                        dxfContent += "0\nTEXT\n8\n0\n"
                        dxfContent += String(format: "10\n%.3f\n20\n%.3f\n30\n%.3f\n40\n%.3f\n1\n\(String(index + 1))\n", coords[1].x*0.9, coords[1].y*0.9, 0.0, 0.1)
                    }
                }
                
                // Remove extra anchors
                for index in similarAnchorIndices.sorted(by: >) {
                    anchors.remove(at: index)
                    //                    camAnchors.remove(at: index)
                }
                
                // End the DXF content
                dxfContent += "0\nENDSEC\n0\nEOF\n"
                
                do {
//                    let destinationURL = try! createFolder(newFolderName: folderName).appending(path: "Room.dxf")
                    try dxfContent.write(to: destinationURL!, atomically: true, encoding: .utf8)
                } catch {
                    print("Error creating DXF file: \(error)")
                }
            }
        }
    }
}
