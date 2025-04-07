/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Class providing custom thresholds for the object detection model.
*/

import CoreML

/// - Tag: ThresholdProvider
/// Class providing customized thresholds for object detection model
class ThresholdProvider: MLFeatureProvider {
    /// The actual values to provide as input
    ///
    /// Create ML Defaults are 0.45 for IOU and 0.25 for confidence.
    /// Technically, relaxing the IOU threshold means
    /// non-maximum-suppression (NMS) becomes stricter (fewer boxes are shown).
    
    open var values = [
        "iouThreshold": MLFeatureValue(double: 0.5),
        "confidenceThreshold": MLFeatureValue(double: 0.25)
    ]

    /// The feature names the provider has, per the MLFeatureProvider protocol
    var featureNames: Set<String> {
        return Set(values.keys)
    }

    /// The actual values for the features the provider can provide
    func featureValue(for featureName: String) -> MLFeatureValue? {
        return values[featureName]
    }
}
