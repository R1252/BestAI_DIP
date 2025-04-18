/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View controller extension for the on-boarding experience.
*/

import UIKit
import ARKit

extension CustomViewController: ARCoachingOverlayViewDelegate {
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
//        hideMeshButton.isHidden = true
//        resetButton.isHidden = true
//        planeDetectionButton.isHidden = true
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
//        hideMeshButton.isHidden = false
//        resetButton.isHidden = false
//        planeDetectionButton.isHidden = false
    }

    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
//        resetButtonPressed(self)
    }

    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = customCaptureView.captureSession.arSession
        coachingOverlay.delegate = self
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        customCaptureView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}
