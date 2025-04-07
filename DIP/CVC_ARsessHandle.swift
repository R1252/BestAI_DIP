/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension to handle an ARSession.
*/

import UIKit
import ARKit
import Vision
import RoomPlan

extension CustomViewController {
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        statusLabel.text = "ARKit Error:\(error.localizedDescription)"
//         Present an error message to the user.
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({$0}).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                print("Debug - ARSession Failed")
//                    if let configuration = self.session.configuration {
//                        self.session.run(configuration, options: .resetSceneReconstruction)
//                    }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    //
    func sessionWasInterrupted(_ session: ARSession) {
        //        infoLabel.text = "ARKit session was interrupted"
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        //        exportButton.isHidden = true
        return true
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    }
    
    // MARK: - ARSessionDelegate
    
    /// Method called when the ARSession produces a new frame
    ///
    /// - parameter frame: The ARFrame containing information about the last
    ///                    captured video frame and the state of the world
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        statusLabel.text = customCaptureView.statusLabelText
        // prevent directly referencing the frame
        let camTransform = frame.camera.transform
        let image = frame.capturedImage
        
        if scanSwitch.isOn {
            frameCounter += 1
            if frameCounter == frameInterval {
                frameCounter = 0
                // ML Model
                handleML(image: image)
            }
        } else {
            detectionOverlay.sublayers = nil
            detectionBounds = []
        }
        
        handleRoomView(cameraTransform: camTransform)
        // Handle Relocalized Model
        if !customCaptureView.firstScan {
            handleRelocalizedSmallModel()
        }
    }
    
    func handleRoomView(cameraTransform: simd_float4x4) {
        for node in roomView.scene!.rootNode.childNodes {
            if node.name == "userNode" {
                node.removeFromParentNode()
            }
        }
        //         Get current AR camera angle
        let angle = cameraTransform.eulerAngles.y
        
        guard let floor = roomFloor else {
            return
        }
        
        let floorPosition = floor.transform.position
        let arCamPosition = cameraTransform.position
        
        // 3 is just a constant
        roomScale = max(roomScale,sqrt(pow((floorPosition.x - arCamPosition.x), 2) + pow((floorPosition.z - arCamPosition.z), 2)) * 3)
        //        print("Debug - diff", diff)
        let length = min(max(15,roomScale),30)
        
        // update cameraNode
        let position = floor.transform.position
        cameraNode.position = SCNVector3(x: position.x + length * sin(angle),
                                         y: position.y + length * /*2/3*/ 4/5,
                                         z: position.z + length * cos(angle))
        
        cameraNode.eulerAngles = SCNVector3(-Float.pi/9,angle,0)
        cameraNode.camera?.fieldOfView = 60.0
        
        //add user location
        let sphere = SCNSphere(radius: 0.5)
        let userNode = SCNNode(geometry: sphere)
        userNode.name = "userNode"
        userNode.geometry?.materials.first?.diffuse.contents = UIColor.red
        userNode.transform = SCNMatrix4(cameraTransform)
        roomView.scene?.rootNode.addChildNode(userNode)
        
        for node in customCaptureView.wallNodes {
            if customCaptureView.nodeBehindCamera(node: node, arCam: arCamPosition) {
                node.geometry?.materials.first?.transparency = 0.5
                //                       print("Debug - wallNode detected behind camera")
            }
        }
    }
    
    func handleRelocalizedSmallModel() {
        if customCaptureView.savedStructure != nil && customCaptureView.isScanning == true {
            let finalStructure = customCaptureView.savedStructure!
            customCaptureView.cleanScene()
            customCaptureView.wallNodes.removeAll()
            customCaptureView.surfaceInRoom.removeAll()
            // draw planes
            for plane in finalStructure.floors + finalStructure.walls {
                drawRelocalizedPlanes(plane: plane)
            }
           
            for surface in finalStructure.windows + finalStructure.openings + finalStructure.doors{
                customCaptureView.surfaceInRoom.append(surface)
                drawRelocalizedSurface(surface: surface)
            }
        }
    }
    
    func drawRelocalizedPlanes(plane: CapturedRoom.Surface) {
        let dimensions = plane.dimensions
        let box = SCNBox(width: CGFloat(dimensions.x),
                         height: CGFloat(dimensions.y),
                         length: CGFloat(dimensions.z),
                         chamferRadius: 0.0)
        let node = SCNNode(geometry: box)
        node.transform = SCNMatrix4(plane.transform)
        if plane.category == CapturedRoom.Surface.Category.wall {
            customCaptureView.highlightNode(node)
            customCaptureView.wallNodes.append(node)
        }
        else if plane.category == CapturedRoom.Surface.Category.floor {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        }
        roomView.scene!.rootNode.addChildNode(node)
    }
    
    func drawRelocalizedSurface(surface: CapturedRoom.Surface) {
        let surfaceBox = SCNBox(width: CGFloat(surface.dimensions.x),
                                height: CGFloat(surface.dimensions.y),
                                length: 0.1, chamferRadius: 0.0)
        
        let surfaceNode = SCNNode(geometry: surfaceBox)
        surfaceNode.transform = SCNMatrix4(surface.transform)
        surfaceNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.5)
        surfaceNode.name = surface.identifier.uuidString
        
        customCaptureView.highlightNode(surfaceNode)
        roomView.scene!.rootNode.addChildNode(surfaceNode)
    }
    
    func handleML(image: CVPixelBuffer){
//        let imageOrientation = CGImagePropertyOrientation.up
//        // For object detection, keeping track of the image buffer size
//        // to know how to draw bounding boxes based on relative values.
//        if self.bufferSize == nil /*|| self.lastOrientation != imageOrientation*/ {
//            //                    self.lastOrientation = imageOrientation
//            let pixelBufferWidth = CVPixelBufferGetWidth(image)
//            let pixelBufferHeight = CVPixelBufferGetHeight(image)
//            self.bufferSize = CGSize(width: pixelBufferWidth,
//                                     height: pixelBufferHeight)
//        }
        predictionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: image/*, orientation: imageOrientation*/)
            do {
                try handler.perform([self.yoloRequest])
            } catch {
                print("CoreML request failed with error: \(error.localizedDescription)")
            }
        }
            
        // limit iou and confidence treshold
        let confidenceValue = Double(max(0.3,min(confidenceSlider.value,0.6)))
        let iouValue = Double(max(0.0,min(iouSlider.value,0.6)))
        
        self.thresholdProvider.values = [
            "iouThreshold": MLFeatureValue(double: iouValue),
            "confidenceThreshold": MLFeatureValue(double: confidenceValue)]
        self.yoloRequest.model.featureProvider = self.thresholdProvider
    }
}
