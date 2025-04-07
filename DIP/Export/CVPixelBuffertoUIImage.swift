//
//  CVPixelBuffertoUIImage.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/3/4.
//

import UIKit
import VideoToolbox

extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        
        if let cgImage = cgImage {
            self.init(cgImage: cgImage)
        }
        
        else{
            return nil
        }
    }
}


