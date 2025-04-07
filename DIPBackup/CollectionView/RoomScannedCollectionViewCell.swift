//
//  RoomScannedCollectionViewCell.swift
//  簡單風水
//
//  Created by Ray Septian Togi on 2024/6/13.
//

import UIKit
import QuickLookThumbnailing

class RoomScannedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var roomImage: UIImageView!
    @IBOutlet weak var titleLabel : UILabel!
    var roomURL : URL?
    var folderURL : URL?
    
    func setup(with room: RoomScanned){
        titleLabel.text = room.folderName
        folderURL = documentsDirectory.appendingPathComponent(room.folderName)
        
        do {
            roomURL = try FileManager.default.contentsOfDirectory(at: folderURL!, includingPropertiesForKeys: nil).filter{$0.pathExtension=="usdz"}.first
        }
        catch {
            print("Debug - error in getting roomURL")
        }
        
        generateThumbnailRepresentations(roomURL: roomURL!, completion: { [weak self] image in
               self?.roomImage.image = image
       })
    }
    
    
    
    func generateThumbnailRepresentations(roomURL: URL, completion: @escaping ((_ image: UIImage?) -> Void)) {
        let size: CGSize = CGSize(width: 150, height: 175)
        let scale = UIScreen.main.scale
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: roomURL,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .thumbnail)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if thumbnail == nil || error != nil {
                    completion(nil)
                    print (error!)
                    return
                } else {
                    completion(thumbnail!.uiImage)
                }
            }
        }
    }
}


class NewRoomScannedCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var newScan: UIButton!
}

class GalleryCollectionViewCell: UICollectionViewCell{
    @IBOutlet weak var label: UILabel!
    
    func setup(with name: String) {
//        let filteredName = name.suffix(4)
        var finalName = ""
        if name == "Room.usdz" {
            finalName = "3D Model"
        }
        else if name == "Room_Textured.usdz"{
            finalName = "3D Model_Textured"
        }
        else if name.suffix(4) == "json" {
            finalName = "2D Plan"
        }
        else {
            finalName = name
        }
        label.text = finalName
    }
}
