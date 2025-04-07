//
//  drawBBOverlay.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/5/13.
//
import Foundation
import UIKit
import ARKit
import RealityKit

extension CustomViewController {
    func createBox(at point: CGPoint) {
        let initSize = CGSize(width: 30, height: 30)
        let boxFrame = CGRect(origin: point, size: initSize)
//        let boxView = UIView(frame: boxFrame)
        boxView = UIView(frame: boxFrame)
        boxView.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        boxView.layer.borderWidth = 4.0
        boxView.layer.borderColor = UIColor.black.cgColor
        
        self.view.addSubview(boxView)
//        boxViews.append(boxView)
    }
    
    @objc func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        if customCaptureView.isScanning == false {
            let translation = recognizer.translation(in: self.view)
            switch recognizer.state {
            case .began:
                let startLocation = recognizer.location(in: self.view)
                if boxView.frame.size == CGSizeZero {
                    createBox(at: startLocation)
                }
            case .changed:
                let newWidth = max(0,boxView.frame.width + translation.x)
                let newHeight = max(0,boxView.frame.height + translation.y)
                boxView.frame.size = CGSize(width: newWidth, height: newHeight)
                recognizer.setTranslation(CGPoint.zero, in: boxView)
            default:
                break
            }
        }
        else {
            return
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        if customCaptureView.isScanning == false {
            let tapLocation = gesture.location(in: self.view)
            // 手動
            if insideOf(point: tapLocation, bound: boxView.frame) {
                createAnchor(box: boxView.frame, type: "boxViews")
                print("Debug - selected model's bbox")
            }
            // 半自動
            // fix bug
            for bound in detectionBounds {
                print("Debug - bound", bound)
                if insideOf(point: tapLocation, bound: bound.frame) {
                    createAnchor(box: bound.frame, type: "wall")
                    print("Debug - detectionBounds selected bbox")
                    return
                }
            }
        }
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer){
        let tapLocation = gesture.location(in: self.view)
        if insideOf(point: tapLocation, bound: boxView.frame) {
            boxView.removeFromSuperview()
            boxView = UIView()
            print("Debug - deleted bbox")
            return
       }
        
        // double tap anchors to remove anchors
        if customCaptureView.entity(at: tapLocation) != nil {
            let entity = customCaptureView.entity(at: tapLocation)!
            for child in entity.children {
                child.removeFromParent()
            }
            customCaptureView.scene.removeAnchor(entity.anchor!)
            entity.removeFromParent()
            
            for (index,defectAnchor) in customCaptureView.defectAnchors.enumerated() {
                if defectAnchor.name == entity.name {
                    customCaptureView.camAnchors.remove(at: index)
                    customCaptureView.defectAnchors.remove(at: index)
                    for _ in 0 ... 3{
                        csvData.bounds_2d!.remove(at: index*4)
                        csvData.bounds_3d!.remove(at: index*4)
                    }
                    csvData.defect_length!.remove(at: index)
                    csvData.defect_width!.remove(at: index)
                    csvData.cam_position!.remove(at: index)
                    savedImages.remove(at: index)
                }
            }
        }
    }
    
    func insideOf(point : CGPoint, bound: CGRect) -> Bool{
        if point.x < bound.maxX && point.x > bound.minX {
            if point.y < bound.maxY && point.y > bound.minY {
                return true
            }
        }
        return false
    }
}
