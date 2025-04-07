//
//  createAnchor.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/3/18.
//
import ARKit
import RealityKit

extension CustomViewController {
    func createAnchor(box: CGRect, type: String){
        // Enable to input width
//        widthSelectButton.isHidden.toggle()
//        widthPicker.isHidden.toggle()
        var type = type
        let anchorNumber = customCaptureView.anchorNumberForIdentification
        
        guard let camTransform = customCaptureView.captureSession.arSession.currentFrame?.camera.transform,
              let image = customCaptureView.captureSession.arSession.currentFrame?.capturedImage
        else {
            print("Debug - Failed to capture current frame.")
            return
        }

        if type == "boxViews" {
//            boxViews[boxViews.count-1].removeFromSuperview()
//            boxViews.remove(at: boxViews.count-1)
            boxView.removeFromSuperview()
            boxView = UIView()
            if camTransform.eulerAngles.x  >= .pi/6{
                type = "ceiling"
            }
            else if camTransform.eulerAngles.x  <= -.pi/6 {
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
           guard let tempResult = customCaptureView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first else {
               self.statusLabel.text = "Raycast didn't detect anything"
               print("Debug - Raycast didn't detect anything")
               return
           }
           raycastResults.append(tempResult)
           let tempAnchor = AnchorEntity(raycastResult: tempResult)
           raycastAnchors.append(tempAnchor)
       }
        
        // Possible feature add text to the anchor
        let transparentMaterial = UnlitMaterial(color: .black.withAlphaComponent(0.3))
        
        // get boxView's width, height, and defect length
        let boxViewWidth = getBoxViewWidthHeight(raycastResults: raycastResults)[0]
        let boxViewHeight = getBoxViewWidthHeight(raycastResults: raycastResults)[1]
        let defectLength = getBoxViewWidthHeight(raycastResults: raycastResults)[2]
        
        let boxModel = MeshResource.generateBox(width: boxViewWidth, height: 0.005, depth: boxViewHeight)
        let boxEntity = ModelEntity(mesh: boxModel, materials: [transparentMaterial])
        boxEntity.name = String(anchorNumber)
        boxEntity.generateCollisionShapes(recursive: true)
        customCaptureView.installGestures(.all, for: boxEntity)
        
        raycastAnchors[2].addChild(boxEntity)
        customCaptureView.scene.addAnchor(raycastAnchors[2])
//        customCaptureView.scene.addAnchor(raycastAnchors[1])
        
        // take screenshot
        guard let capturedImage = UIImage(pixelBuffer: image) else {
            self.statusLabel.text = "Failed to capture image."
            print("Debug - Failed to capture image.")
            return
        }
        
        DispatchQueue.global(qos: .background).async { [self] in
            // Save to CSV on background thread
            saveToCSV(raycastResults: raycastResults, points: points, anchorNumber: anchorNumber, cameraTransform: camTransform, defect_length: defectLength)
        }
        
        let tempImage = CustomImage(image: capturedImage, bounds: box, type: type)
        savedImages.append(tempImage)
        
        createImageHolder(width: CGFloat(boxViewWidth), length: CGFloat(boxViewHeight), transform: raycastResults[2].worldTransform, image: capturedImage)
        
        customCaptureView.anchorNumberForIdentification += 1
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
        customCaptureView.camAnchors.append(camAnchor)
        customCaptureView.defectAnchors.append(anchor)
        
        csvData.bounds_3d!.append(contentsOf: [raycastResults[0].worldTransform.position,
                                              raycastResults[1].worldTransform.position,
                                              raycastResults[3].worldTransform.position,
                                              raycastResults[4].worldTransform.position])
        
        csvData.bounds_2d!.append(contentsOf: [points[0],
                                              points[1],
                                              points[3],
                                              points[4]])
        
        csvData.defect_length!.append(defect_length)
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

