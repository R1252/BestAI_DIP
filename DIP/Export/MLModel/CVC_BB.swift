/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Convenience extension to draw bounding boxes.
*/

import UIKit
import Vision
import ARKit
import RealityKit

extension CustomViewController {
    /// Sets up CALayers for rendering bounding boxes
    func setupLayers() {
        DispatchQueue.main.async { [self] in
            // container layer that has all the renderings of the observations
            detectionOverlay = CALayer()
            detectionOverlay.bounds = CGRect(x: 0.0,
                                             y: 0.0,
                                             width: self.customCaptureView.frame.width,
                                             height: self.customCaptureView.frame.height)
            detectionOverlay.position = CGPoint(x: self.rootLayer.bounds.midX,
                                                y: self.rootLayer.bounds.midY)
            rootLayer.addSublayer(detectionOverlay)
        }
    }

    /// Update the size of the overlay layer if the customCaptureView size changed
    func updateDetectionOverlaySize() {
        DispatchQueue.main.async {
            self.detectionOverlay.bounds = CGRect(x: 0.0, 
                                                  y: 0.0,
                                                  width: self.customCaptureView.frame.width,
                                                  height: self.customCaptureView.frame.height)
        }
    }

    /// Update layer geometry when needed
    func updateLayerGeometry() {
        DispatchQueue.main.async {
            let bounds = self.rootLayer.bounds
            var scale: CGFloat

            let xScale: CGFloat = bounds.size.width / self.customCaptureView.frame.height
            let yScale: CGFloat = bounds.size.height / self.customCaptureView.frame.width

            scale = fmax(xScale, yScale)
            if scale.isInfinite {
                scale = 1.0
            }
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            self.detectionOverlay.position = CGPoint(x: bounds.midX, y: bounds.midY)
            CATransaction.commit()
        }
    }
    
//    func detection(pixelBuffer: CVPixelBuffer) {
//        guard let detections = yoloRequest.results as? [VNRecognizedObjectObservation] else {
//            print("Request did not return recognized objects: \(yoloRequest.results?.debugDescription ?? "[No results]")")
//            return
//        }
//        
//        do {
////            let outputSetting: [VNImageOption: Any] = [
////                kCVPixelBufferPixelFormatTypeKey as VNImageOption: kCVPixelFormatType_32BGRA,
////                kCVPixelBufferWidthKey as VNImageOption : customCaptureView.frame.width,
////                kCVPixelBufferHeightKey as VNImageOption : customCaptureView.frame.height
////            ]
////            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: outputSetting)
//            
//            // 09.10 commented
////            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
////            try handler.perform([yoloRequest])
////            guard let results = yoloRequest.results as? [VNRecognizedObjectObservation] else {
////                return
////            }
//            
////            var detections : [Detection] = []
//            for result in results {
//                let flippedBox = CGRect(x: result.boundingBox.origin.x,
//                                        y: 1 - result.boundingBox.origin.y - result.boundingBox.height,
//                                        width: result.boundingBox.width,
//                                        height: result.boundingBox.height)
//                let box = VNImageRectForNormalizedRect(flippedBox, Int(customCaptureView.frame.width), Int(customCaptureView.frame.height))
//                
//                guard let label = result.labels.first?.identifier as? String,
//                      let colorIndex = classes.firstIndex(of: label) else {
//                    return
//                }
//                
//                let detection = Detection(box: box, confidence: result.confidence, label: label, color: colors[colorIndex])
//            }
//            
//            drawBoxes(detections: detections)
//        }
//        
//        // commented 09.10
////        catch let error {
////            print(error)
////            return
////        }
//    }
    
    func detection(request: VNRequest, error : Error?) {
        if let error = error {
            print("An error occurred with the vision request: \(error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        guard let detections = request.results as? [VNRecognizedObjectObservation] else {
            print("Request did not return recognized objects: \(yoloRequest.results?.debugDescription ?? "[No results]")")
            return
        }
        
        guard !detections.isEmpty else {
            removeBoxes()
            if !results.isEmpty {
                print("Debug - results rn and previous results are empty")
            }
            results = []
            return
        }
        
//        if showBoxes {
            drawBoxes(detections: detections)
//        }
    }

    /// Draws bounding boxes based on the object observations
    /// - parameter detections: The list of object observations from the object detector
    func drawBoxes(detections: [VNRecognizedObjectObservation]) {
        let arView = self.customCaptureView!
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            // remove all the old recognized objects
            detectionOverlay.sublayers = nil
            detectionBounds = []
            customCaptureView.statusLabelText = "無偵測到損壞"
            
            for detection in detections {
                let objectBounds = bounds(for: detection)
                let point = CGPoint(x: objectBounds.midX, y: objectBounds.midY)
//                let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
                let results = arView.raycast(from: point, allowing: .existingPlaneGeometry, alignment: .any)
                guard let topLabel = detection.labels.first?.identifier else {
                    customCaptureView.statusLabelText = "Object observation has no labels"
                    continue
                }
                guard let result = results.first else {
                    customCaptureView.statusLabelText = "Raycast didn't detect anything"
                    break
                }
                
                if isWall(location: result.worldTransform.position, wallPoints: customCaptureView.wallPoints) {
                    customCaptureView.statusLabelText = "損壞在牆上"
                    let objectView = UIView(frame: objectBounds)
                    let shapeLayer = createRoundedRectLayerWithBounds(objectBounds)
                    let textLayer = createTextSubLayerInBounds(objectBounds,
                                                               identifier: topLabel,
                                                               confidence : detection.confidence)
                    detectionBounds.append(objectView)
                    detectionOverlay.addSublayer(shapeLayer)
                    shapeLayer.addSublayer(textLayer)
                }
                customCaptureView.statusLabelText = "有損壞但不在牆"
            }
        updateLayerGeometry()
        CATransaction.commit()
    }   
    
    func bounds(for observation: VNRecognizedObjectObservation) -> CGRect {
        let boundingBox = observation.boundingBox
        // Coordinate system is like macOS, origin is on bottom-left and not top-left
        // The resulting bounding box from the prediction is a normalized bounding box with coordinates from bottom left, it needs to be flipped along the y axis
        let fixedBoundingBox = CGRect(x: boundingBox.origin.x,
                                      y: 1.0 - boundingBox.origin.y - boundingBox.height,
                                      width: boundingBox.width,
                                      height: boundingBox.height)
        // Return a flipped and scaled rectangle corresponding to the coordinates in the sceneView
        return VNImageRectForNormalizedRect(fixedBoundingBox, Int(customCaptureView.frame.width), Int(customCaptureView.frame.height))
    }
    
    /// Creates a rounded rectangle layer with the given bounds
    /// - parameter bounds: The bounds of the rectangle
    /// - returns: A newly created CALayer
    func createRoundedRectLayerWithBounds(_ bounds: CGRect) -> CALayer {
        let shapeLayer = CALayer()
        shapeLayer.bounds = bounds
        shapeLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shapeLayer.borderColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        shapeLayer.borderWidth = 6.0
        shapeLayer.cornerRadius = 1.0
        return shapeLayer
    }
    
    /// Creates a text layer to display the label for the given box
    /// - parameters:
    ///     - bounds: Bounds of the detected object
    ///     - identifier: Class label for the detected object
    ///     - confidence: Confidence in the prediction
    /// - returns: A newly created CATextLayer
    func createTextSubLayerInBounds(_ bounds: CGRect, identifier: String, confidence : Float) -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.foregroundColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        let fontSize = min(bounds.size.height * 0.1, 25.0)
        let largeFont = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let attributes = [NSAttributedString.Key.font: largeFont,
                          NSAttributedString.Key.foregroundColor: UIColor.black]
        let attributedString = NSMutableAttributedString(string: "\(identifier) : \(round(confidence*100))", attributes: attributes)
        textLayer.string = attributedString
        textLayer.frame = CGRect(x: bounds.origin.x - fontSize*8/2,
                                 y: bounds.origin.y,
                                 width: fontSize*8,
                                 height: fontSize)
        textLayer.backgroundColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.alignmentMode = .center
        textLayer.contentsScale = 2.0
        return textLayer
    }
    
    /// Removes all bounding boxes from the screen
    func removeBoxes() {
        drawBoxes(detections: [])
    }
    
    // instead of accessing the mesh, just use coordinates of walls
    func isWall(location: SIMD3<Float>, wallPoints : [SIMD2<Float>]) -> Bool  {
        let tolerance : Float = 0.06
        for point in wallPoints {
            if location.x >= point.x - tolerance && location.x <= point.x + tolerance {
                if location.z >= point.y - tolerance && location.z <= point.y + tolerance{
                    return true
                }
            }
        }
        return false
    }
}

func interpolateBetweenPoints(start: SIMD2<Float>, end: SIMD2<Float>, interval: Float = 0.1) -> [SIMD2<Float>] {
    var points: [SIMD2<Float>] = []
    // Calculate the distance between the two points
    let direction = end - start
    let distance = length(direction)
    
    // Calculate the number of steps based on the interval
    let steps = Int(distance / interval)
    
    // Normalize the direction to move in equal steps
    let normalizedDirection = normalize(direction)
    
    // Generate points along the path
    for step in 0...steps {
        let t = Float(step) * interval
        let interpolatedPoint = start + normalizedDirection * t
        points.append(interpolatedPoint)
    }
    
    return points
}
