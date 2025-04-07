//
//  tempFile.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/5/15.
//

import Foundation

extension CustomViewController {
    func createFolder(newFolderName: String!) throws -> URL {
        var folderURL = documentsDirectory.appendingPathComponent(newFolderName)
        
        let folderList = try FileManager.default.contentsOfDirectory(at: .documentsDirectory, includingPropertiesForKeys: nil)
        print("Debug folderList", folderList)
        var folderNames : [String] = []
        var folderNum = 0
        
        for folder in folderList {
            folderNames.append(folder.lastPathComponent)
            let name = folder.lastPathComponent.filter{$0.isLetter}
            // check how many folders are similarly named
            if name == newFolderName {
                folderNum += 1
            }
        }
        
        for folderName in folderNames {
            if folderName == newFolderName {
                // if user says replace folder
                if (1==2) {
                    print("Debug - folderName", folderName)
                    clearFolder(folderURL)
                }
                // if user says no, don't replace
                else {
                    let updatedFolderName = folderName + "_" + "\(folderNum)"
                    userInputText = updatedFolderName
                    folderURL = documentsDirectory.appendingPathComponent(updatedFolderName)
                }
            }
        }
        
        // create folder
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        
        return folderURL
    }
}

func clearFolder(_ destinationFolderURL: URL) {
    do {
        try FileManager.default.removeItem(at: destinationFolderURL)
    } catch {
        print("Debug - error \(error)")
    }
}
