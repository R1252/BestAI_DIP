//
//  export_images.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/3/18.
//
import UIKit

extension CustomViewController {
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
            
//            let testBound = CGRect(x: image.size.width - bounds.origin.x - bounds.width,
//                                   y: image.size.height - bounds.origin.y - bounds.height,
//                                   width: bounds.width,
//                                   height: bounds.height)
            
            //Draw rectangle
            context.cgContext.setFillColor(UIColor.clear.cgColor)
            context.cgContext.setStrokeColor(UIColor.red.cgColor)
            context.cgContext.setLineWidth(10)

            context.cgContext.addRect(testBound)
//            context.cgContext.addRect(bounds)
            context.cgContext.drawPath(using: .fillStroke)
        }
       
       return newImage
   }
}

struct CustomImage {
    var image : UIImage
    var bounds : CGRect
    var location : String
    
    init(image: UIImage, bounds: CGRect, type: String) {
        self.image = image
        self.bounds = bounds
        self.location = type
    }
}
