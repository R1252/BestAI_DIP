//
//  ScanViewExportFunctions.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//
import UIKit
import ARKit
import RealityKit
import SceneKit
import SceneKit.ModelIO
import ModelIO

extension ScanViewController {
    func exportUSDZ(){
        let destinationURL = destinationFolderURL!.appending(path: "Room.usdz")
        let capturedRoomURL = destinationFolderURL!.appending(path: "RoomData.json")
        
        guard let structure = scanView.savedStructure else {
            print("Debug - there are no savedStructure available")
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(scanView.savedStructure)
            try jsonData.write(to: capturedRoomURL)
            try structure.export(to: destinationURL, exportOptions: .mesh)
            
        } catch {
            print("Error = \(error)")
        }
    }
    
    func exportFloorPlan(){
        guard let structure = scanView.savedStructure else {
            print("debug - no floor plan created due to no savedStructure")
            return
        }
        // AutoCAD
        _ = FloorPlan(structure: structure, defectAnchors: scanView.defectAnchors, camAnchors: scanView.camAnchors, folderURL: destinationFolderURL!)
    }
    
    func saveImage(images: [CustomImage]){
        for (index,customImage) in images.enumerated() {
            //Create labelled image
            let labelledImage = labelImage(loc: self.userInputText!, num: index + 1, customImage: customImage)
            let fileURL = self.destinationFolderURL!.appendingPathComponent("\(index + 1).jpg")
            let labelledFileURL = self.destinationFolderURL!.appendingPathComponent("\(index + 1)_Label.jpg")
            if let imageData = customImage.image.jpegData(compressionQuality: 1.0),
               let labelledImageData = labelledImage.jpegData(compressionQuality: 1.0) {
                do {
                    try imageData.write(to: fileURL)
                    try labelledImageData.write(to: labelledFileURL)
                }
                catch {
                    print("Error writing image data: \(error)")
                }
            }
        }
        
        //clear after done
        savedImages = []
    }
    
    func labelImage(loc: String, num: Int, customImage: CustomImage) -> UIImage {
        // A default, formatted, localizable date string.
        let image = customImage.image
        let bounds = customImage.bounds
        let date = Date.now
        let dateFormatted = date.formatted(date: .abbreviated, time: .standard)
        
        // Set up font specific variables
        let text = NSString(string: """
                           Picture Number  : #\(num)
                           Date            : \(dateFormatted)
                           Location        : \(loc)
                           """)
        
        // Setup image using passed image
        let format = UIGraphicsImageRendererFormat(for: UITraitCollection(displayScale: 1))
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let newImage = renderer.image { context in
            //Draw original image
            image.draw(at: CGPoint.zero)
            
            //Define text attributes
            let textFontAttributes = [
                NSAttributedString.Key.font : UIFont(name: "Helvetica Bold", size: 24)!,
                NSAttributedString.Key.foregroundColor : UIColor.white,
                NSAttributedString.Key.backgroundColor : UIColor.gray.withAlphaComponent(0.3)
            ]
            as [NSAttributedString.Key : Any]
            
            //Draw text
            let textSize = text.size(withAttributes: textFontAttributes)
            let x = image.size.width - textSize.width * 1.2
            let y = image.size.height - textSize.height * 1.2
            let rect = CGRect(x: x,
                              y: y,
                              width: textSize.width,
                              height: textSize.height)
            text.draw(in: rect, withAttributes: textFontAttributes)
            
            // there's a size difference between saved image and screen size
            let screenSize = view.frame.size
            let xRatio = image.size.width / screenSize.width
            let yRatio = image.size.height / screenSize.height
            
            let testBound = CGRect(x: bounds.origin.x * xRatio,
                                   y: bounds.origin.y * yRatio,
                                   width: bounds.width * xRatio,
                                   height: bounds.height * yRatio)
            
            //Draw rectangle
            context.cgContext.setFillColor(UIColor.clear.cgColor)
            context.cgContext.setStrokeColor(UIColor.red.cgColor)
            context.cgContext.setLineWidth(10)
            
            context.cgContext.addRect(testBound)
            context.cgContext.drawPath(using: .fillStroke)
        }
        
        return newImage
    }
    
    func createFolder(newFolderName: String!) throws -> URL {
        var folderURL = documentsDirectory.appendingPathComponent(newFolderName)
        
        let folderList = try FileManager.default.contentsOfDirectory(at: .documentsDirectory, includingPropertiesForKeys: nil)
        print("Debug folderList", folderList)
        var folderNames : [String] = []
        var folderNum = 0
        
        for folder in folderList {
            folderNames.append(folder.lastPathComponent)
            let name = folder.lastPathComponent.filter{$0.isLetter}
            // check how many folders are similarly named
            if name == newFolderName {
                folderNum += 1
            }
        }
        
        for folderName in folderNames {
            if folderName == newFolderName {
                // if user says replace folder
                if (1==2) {
                    print("Debug - folderName", folderName)
                    clearFolder(folderURL)
                }
                // if user says no, don't replace
                else {
                    let updatedFolderName = folderName + "_" + "\(folderNum)"
                    userInputText = updatedFolderName
                    folderURL = documentsDirectory.appendingPathComponent(updatedFolderName)
                }
            }
        }
        
        // create folder
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        
        return folderURL
    }
    
    func clearFolder(_ destinationFolderURL: URL) {
        do {
            try FileManager.default.removeItem(at: destinationFolderURL)
        } catch {
            print("Debug - error \(error)")
        }
    }
    
    func createAnchor(box: CGRect, type: String){
        var type = type
        let anchorNumber = scanView.anchorNumberForIdentification
        guard let currentFrame = scanView.captureSession.arSession.currentFrame
        else {
            print("Failed to capture current frame.")
            return
        }
//         Get the camera's position and orientation from the current frame
        let cameraTransform = currentFrame.camera.transform
        if type == "boxViews" {
            boxView.removeFromSuperview()
            boxView = UIView()
            if currentFrame.camera.eulerAngles.x >= .pi/6{
                type = "ceiling"
            }
            else if currentFrame.camera.eulerAngles.x <= -.pi/6 {
                type = "floor"
            }
            else {
                type = ""
            }
        }
        
        //In the default Core Graphics coordinate space, the origin is located in the lower-left corner of the rectangle and the rectangle extends towards the upper-right corner.
        // If the context has a flipped-coordinate space—often the case on iOS—the origin is in the upper-left corner and the rectangle extends towards the lower-right corner.
       
        var raycastResults : [ARRaycastResult] = []
        var raycastAnchors : [AnchorEntity] = []
        
        let points = [
            box.origin, // upper left
            CGPoint(x: box.maxX, y: box.minY), // upper-right
            CGPoint(x: box.midX, y: box.midY), // middle
            CGPoint(x: box.maxX, y: box.maxY), // lower-right
            CGPoint(x: box.origin.x, y: box.maxY) // lower-left
        ]
        
        for point in points {
            let tempResult = scanView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first
            if tempResult != nil {
                raycastResults.append(tempResult!)
                let tempAnchor = AnchorEntity(raycastResult: tempResult!)
                raycastAnchors.append(tempAnchor)
            }
            else {
                self.statusLabel.text = "Raycast didn't detect anything"
                print("Raycast didn't detect anything")
                return
            }
        }
        
        let transparentMaterial = UnlitMaterial(color: .black.withAlphaComponent(0.5))
        
        // get boxView's width, height, and defect length
        let boxViewWidth = getBoxViewWidthHeight(raycastResults: raycastResults)[0]
        let boxViewHeight = getBoxViewWidthHeight(raycastResults: raycastResults)[1]
        let defect_length : Float = 0.0
        
        let boxModel = MeshResource.generateBox(width: boxViewWidth, height: 0.005, depth: boxViewHeight)
        let boxEntity = ModelEntity(mesh: boxModel, materials: [transparentMaterial])
        boxEntity.name = String(anchorNumber)
        boxEntity.generateCollisionShapes(recursive: true)
        scanView.installGestures(.all, for: boxEntity)
        
        raycastAnchors[2].addChild(boxEntity)
        scanView.scene.addAnchor(raycastAnchors[2])
        
        // save the information to csvData
        saveToCSV(raycastResults: raycastResults, points: points, anchorNumber: anchorNumber, cameraTransform: cameraTransform, defect_length: defect_length)

        // take screenshot
        guard let capturedImage = UIImage(pixelBuffer: currentFrame.capturedImage) else {
            self.statusLabel.text = "Failed to capture image."
            print("Failed to capture image.")
            return
        }
        
        let tempImage = CustomImage(image: capturedImage, bounds: box, type: type)
        savedImages.append(tempImage)
        
        createImageHolder(width: CGFloat(boxViewWidth), length: CGFloat(boxViewHeight), transform: raycastResults[2].worldTransform, image: capturedImage)
        
        scanView.anchorNumberForIdentification += 1
        return
    }
    
    func createImageHolder(width: CGFloat, length: CGFloat, transform: simd_float4x4, image: UIImage) {
        let box = SCNBox(width: width, height: 0.1, length: length, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        box.materials = [material]
        let node = SCNNode(geometry: box)
        node.transform = SCNMatrix4(transform)
        print("Debug roomView imageHolder transform", transform)
        
        roomView.scene?.rootNode.addChildNode(node)
    }
    
    func saveToCSV(raycastResults: [ARRaycastResult], points: [CGPoint], anchorNumber: Int, cameraTransform: simd_float4x4, defect_length : Float){
        // For 2D Plan
        let anchor = ARAnchor(name: String(anchorNumber),transform: raycastResults[2].worldTransform)
        let camAnchor = ARAnchor(name: String(anchorNumber)+"_Cam", transform: cameraTransform)
        scanView.camAnchors.append(camAnchor)
        scanView.defectAnchors.append(anchor)
        
        csvData.bounds_3d!.append(contentsOf: [raycastResults[0].worldTransform.position,
                                              raycastResults[1].worldTransform.position,
                                              raycastResults[3].worldTransform.position,
                                              raycastResults[4].worldTransform.position])
        
        csvData.bounds_2d!.append(contentsOf: [points[0],
                                              points[1],
                                              points[3],
                                              points[4]])
        
        csvData.defect_length!.append(defect_length)
        csvData.defect_width!.append(1)
        csvData.cam_position!.append(contentsOf: [camAnchor.transform.position])
    }
    
    func getBoxViewWidthHeight(raycastResults: [ARRaycastResult]) -> [Float] {
        var boxViewWidth : Float = 0.0
        var defect_length : Float = 0.0
        let xDiff = abs(raycastResults[0].worldTransform.position.x - raycastResults[3].worldTransform.position.x)
        let zDiff = abs(raycastResults[0].worldTransform.position.z - raycastResults[3].worldTransform.position.z)
        
        if xDiff >= zDiff {
            boxViewWidth = xDiff
        } else {
            boxViewWidth = zDiff
        }
        
        let height = abs(raycastResults[0].worldTransform.position.y - raycastResults[3].worldTransform.position.y)
        
        if boxViewWidth > height * 1.5 {
            defect_length = boxViewWidth
        }
        else if height > boxViewWidth * 1.5{
            defect_length = boxViewWidth
        }
        else {
            defect_length = sqrt(boxViewWidth*boxViewWidth+height*height)
        }
        
        return [boxViewWidth,height,defect_length]
    }

}
