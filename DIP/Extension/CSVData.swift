//
//  CSVData.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/1/6.
//

import Foundation
import ARKit

struct CSVData: Codable {
    var bounds_2d : [CGPoint]?
    var bounds_3d : [simd_float3]?
    var cam_position : [simd_float3]?
    var defect_length : [Float]?
    var defect_width : [Float]?
    
    init() {
        bounds_2d = []
        bounds_3d = []
        cam_position = []
        defect_length = []
        defect_width = []
    }
    
    /// exports defect data as CSV
    func exportCSV(destinationFolderURL: URL, savedImages: [CustomImage]) {
        let bounds_2d = self.bounds_2d!
        let bounds_3d = self.bounds_3d!
        let cam_position = self.cam_position!
        let defect_length = self.defect_length!
        let defect_width = self.defect_width!
        // Prepare data
        let headers = ["defects","location","defect_length (cm)","defect_width (mm)","defect_category","image_name","pt1_2d_x","pt1_2d_y","pt1_3d_x","pt1_3d_y",
                       "pt1_3d_z","pt2_2d_x","pt2_2d_y","pt2_3d_x","pt2_3d_y","pt2_3d_z", "pt3_2d_x"
                       ,"pt3_2d_y","pt3_3d_x","pt3_3d_y","pt3_3d_z","pt4_2d_x","pt4_2d_y","pt4_3d_x","pt4_3d_y","pt4_3d_z","carama_3d_x","carama_3d_y","carama_3d_z"]
        // Create CSV content
        var csvText = headers.joined(separator: ",") + "\n"
        csvText += "\n"
        
        for (index,cam) in cam_position.enumerated() {
            let i = index*4
            
            // prevent errors with defect_width
            var defectWidth : Float = 0.0
            if defect_width.count == cam_position.count {
                defectWidth = defect_width[index]
            }
            
            let row = ["\(index)",
                       "\(savedImages[index].location)",
                       "\(defect_length[index] * 100)",
                       "\(defectWidth)",
                       /*"paint peeling"*/"2",
                       "\(index+1).jpg",
                       "\(bounds_2d[i].x)", "\(bounds_2d[i].y)",
                       "\(bounds_3d[i].x)", "\(bounds_3d[i].y)", "\(bounds_3d[i].z)",
                       "\(bounds_2d[i+1].x)", "\(bounds_2d[i+1].y)",
                       "\(bounds_3d[i+1].x)", "\(bounds_3d[i+1].y)", "\(bounds_3d[i+1].z)",
                       "\(bounds_2d[i+2].x)", "\(bounds_2d[i+2].y)",
                       "\(bounds_3d[i+2].x)", "\(bounds_3d[i+2].y)", "\(bounds_3d[i+2].z)",
                       "\(bounds_2d[i+3].x)", "\(bounds_2d[i+3].y)",
                       "\(bounds_3d[i+3].x)", "\(bounds_3d[i+3].y)", "\(bounds_3d[i+3].z)",
                       "\(cam.x)",
                       "\(cam.y)",
                       "\(cam.z)"]
            let rowString = row.joined(separator: ",")
            csvText += rowString + "\n\n\n"
        }
        let fileURL = destinationFolderURL.appendingPathComponent("defect.csv")

        // Write the CSV file
        try! csvText.write(to: fileURL, atomically: true, encoding: .utf8)
    }

}
