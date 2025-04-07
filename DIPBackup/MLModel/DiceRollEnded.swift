///// - Tag: hasRollEnded
///// Determines if a roll has ended with the current defect values O(n^2)
/////
///// - parameter observations: The object detection observations from the model
///// - returns: True if the roll has ended
//func hasRollEnded(observations: [VNRecognizedObjectObservation]) -> Bool {
//    // First check if same number of defect were detected
//    if lastObservations.count != observations.count {
//        lastObservations = observations
//        return false
//    }
//    var matches = 0
//    for newObservation in observations {
//        for oldObservation in lastObservations {
//            // If the labels don't match, skip it
//            // Or if the IOU is less than 85%, consider this box different
//            // Either it's a different die or the same die has moved
//            if newObservation.labels.first?.identifier == oldObservation.labels.first?.identifier &&
//                intersectionOverUnion(oldObservation.boundingBox, newObservation.boundingBox) > 0.85 {
//                matches += 1
//            }
//        }
//    }
//    lastObservations = observations
//    return matches == observations.count
//}



// THIS CAN BE REALLY GOOD TO SEE IF I HAVE SAVED CRACKED ON LOCATION NEAR HERE OR NOT
// OPTION 1 : LETS SAY I HAVE A CRACK SAVED AS A SQUARE FROM (20,50) AND (50, 100) THEN I SAY IF IT'S AROUND THAT AREA
// DONT SAVE ANY ANCHOR OR EVEN DETECT CRACK
