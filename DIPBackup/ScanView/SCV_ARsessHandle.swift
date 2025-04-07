//
//  SCV_ARsessHandle.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//

import UIKit
import ARKit
import Vision
import RoomPlan

extension ScanViewController {
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
        frameCounter += 1
        handleRoomView(frame: frame)
        if frameCounter >= 60 {
//            print("Debug - Frame Counter \(frameCounter)")
            let cam = frame.camera
            camAngle = cam.eulerAngles.x * 180/(.pi)
            
            let dist = scanView.raycast(from: CGPoint(x: scanView.frame.midX,y: scanView.frame.midY),allowing: .estimatedPlane,alignment: .vertical)
            
            guard let closestDist = dist.first else {
                measurementLabel.text = "Unable to get distance."
                return
            }
            
            camDist = getDistance(cam.transform.position, closestDist.worldTransform.position)
            optimalDistance = (scanView.wallHeight + 0.12)/(deviceHeightWidthRatio)
            
            print("Debug - wallHeight, \(scanView.wallHeight), oDist: \(optimalDistance)")
            
            let relativeDistance = camDist - optimalDistance
            
            if relativeDistance <= 0 {
                measurementLabel.text = String(format: "Step back: %.2f, Angle: %.1f", relativeDistance, camAngle)
            } else {
                measurementLabel.text = String(format: "Step forward: %.2f, Angle: %.1f", relativeDistance, camAngle)
            }
            frameCounter = 0
        }
    }
    
    func handleRoomView(frame: ARFrame) {
        for node in roomView.scene!.rootNode.childNodes {
            if node.name == "userNode" {
                node.removeFromParentNode()
            }
        }
//        Get current AR camera angle
        let angle = frame.camera.transform.eulerAngles.y
        let transform = frame.camera.transform
        
        guard let floor = roomFloor else {
            return
        }
        
        let floorPosition = floor.transform.position
        let arCamPosition = transform.position
        
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
        userNode.transform = SCNMatrix4(frame.camera.transform)
        roomView.scene?.rootNode.addChildNode(userNode)
        
        for node in scanView.wallNodes {
            if scanView.nodeBehindCamera(node: node, arCam: arCamPosition) {
                node.geometry?.materials.first?.transparency = 0.5
//                   print("Debug - wallNode detected behind camera")
            }
        }
    }
}

