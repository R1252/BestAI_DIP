//
//  RoomScanned.swift
//  簡單風水
//
//  Created by Ray Septian Togi on 2024/6/13.
//

import UIKit
import ARKit
import SwiftUI

struct RoomScanned: Codable {
    let folderName: String
    var anchorCoords: [[CGPoint]] = []
    /// defect's transform
    var defectProperties : [simd_float4] = []
    /// the four corners of defects
    var bounds_3d : [simd_float3] = []
    /// store doors name, and corresponding state. True = Open/Close, False = Sliding Doors
    var doors : [String:Bool]
    var csvData = CSVData()
    
    init(folderName: String, defectAnchors: [ARAnchor], camAnchors: [ARAnchor], csvData : CSVData, doorsCount: Int) {
        self.folderName = folderName
        self.bounds_3d = csvData.bounds_3d!
        self.doors = [:]
        
        // door style
        for count in 0...doorsCount {
            self.doors["door_\(count)"] = true
            print("Debug door_\(count)", doors["door_\(count)"])
        }
        
        // defect transform
        for (index,defectAnchor) in defectAnchors.enumerated() {
            let coords = getCoords(anchor: defectAnchor, camAnchors: camAnchors[index])
            anchorCoords.insert(coords, at: index)
            defectProperties.append(contentsOf: [defectAnchor.transform.columns.0,
                                                  defectAnchor.transform.columns.1,
                                                  defectAnchor.transform.columns.2,
                                                  defectAnchor.transform.columns.3])
//            print("Debug - anchorTransform", defectAnchor.transform)
        }
        
        self.csvData = csvData
    }
}

var roomScanned: [RoomScanned] = {
    if UserDefaults.standard.roomScannedList?.count == nil {
        return [RoomScanned(folderName: "", defectAnchors: [], camAnchors: [],  csvData: CSVData(), doorsCount: 0)]
    } else {
        return UserDefaults.standard.roomScannedList!
    }
}()

extension UserDefaults {
    private enum UserDefaultsKeys : String {
        case roomScannedList
    }
    var roomScannedList: [RoomScanned]? {
        get {
            if let data = object(forKey: UserDefaultsKeys.roomScannedList.rawValue) as? Data {
                let roomScanned = try? JSONDecoder().decode([RoomScanned].self, from: data)
                return roomScanned
            }
            return nil
        }
        
        set {
            let data = try? JSONEncoder().encode(newValue)
            setValue(data, forKey: UserDefaultsKeys.roomScannedList.rawValue)
        }
    }
}

class EmptyCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {
        // Disable user interaction to make the cell unclickable
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
}
