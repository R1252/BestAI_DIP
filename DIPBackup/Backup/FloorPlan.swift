//
//  FloorPlan.swift
//  RCS
//
//  Created by Ray Septian Togi on 2024/4/8.
//

import RoomPlan

class FloorPlan {
    // Surfaces and objects from our scan result
    private let surfaces: [CapturedRoom.Surface]
    
    var dxfContent = "0\nSECTION\n2\nHEADER\n0\nENDSEC\n0\nSECTION\n2\nTABLES\n0\nENDSEC\n0\nSECTION\n2\nBLOCKS\n0\nENDSEC\n0\nSECTION\n2\nENTITIES\n"
    
    // MARK: - Init
    
    init(capturedRoom: CapturedRoom) {
        self.surfaces = capturedRoom.doors + capturedRoom.openings + capturedRoom.walls + capturedRoom.windows
        drawSurfaces()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Draw
    private func drawSurfaces() {
        for surface in surfaces {
            let surfaceNode = RFPSurface(capturedSurface: surface)
            for (x1,y1,x2,y2) in surfaceNode.points {
                dxfContent += "0\nLINE\n8\n0\n"
                dxfContent += String(format: "10\n%.3f\n20\n%.3f\n11\n%.3f\n21\n%.3f\n",x1, y1, x2, y2)
            }
        }
        // End the DXF content
        dxfContent += "0\nENDSEC\n0\nEOF\n"
        
        do {
            let destinationFolderURL = FileManager.default.temporaryDirectory.appending(path: "Trial")
            let destinationURL = destinationFolderURL.appending(path: "Trialing.dxf")
            try dxfContent.write(to: destinationURL, atomically: true, encoding: .utf8)
            print("DXF file created successfully.")
        } catch {
            print("Error creating DXF file: \(error)")
        }
    }
    
    //    private func drawAnchors() {
    //        for object in anchors {
    //            let objectNode = FloorPlanAnchors(capturedObject: object)
    //            addChild(objectNode)
    //        }
    //    }
}
