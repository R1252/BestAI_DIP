import Foundation
import ModelIO

func loadMDLAsset(from folderURL: URL) -> MDLAsset? {
    let fileURL = folderURL.appending(path: "Room.usdz")
    // Check if the file exists at the given URL
    if FileManager.default.fileExists(atPath: fileURL.path) {
        // Load the MDLAsset if the file exists
        return MDLAsset(url: fileURL)
    } else {
        print("USDZ file not found at path: \(fileURL)")
        return nil
    }
}

func findMeshes(in asset: MDLAsset) -> [MDLMesh] {
    var meshes: [MDLMesh] = []
    
    for index in 0..<asset.count {
        let object = asset.object(at: index)
        
        if let mesh = object as? MDLMesh {
            meshes.append(mesh)
        } else {
            // Traverse the node's children for meshes
            let nodeMeshes = findMeshes(in: object)
            meshes.append(contentsOf: nodeMeshes)
        }
    }
    
    return meshes
}

func findMeshes(in node: MDLObject) -> [MDLMesh] {
    var meshes: [MDLMesh] = []
    
    // Check if the node itself contains a mesh
    if let mesh = node as? MDLMesh {
        meshes.append(mesh)
    }
    
    // Recursively check all children nodes
    for child in node.children.objects {
        meshes.append(contentsOf: findMeshes(in: child))
    }
    
    return meshes
}

// Function to export to OBJ format
func exportToOBJ(mdlAsset: MDLAsset, destinationFolderURL: URL) {
    // Find all the meshes in the asset
    let meshes = findMeshes(in: mdlAsset)
    
    if meshes.isEmpty {
        print("No meshes found in the asset.")
        return
    }
    
    print("Debug - meshes count",meshes.count)
    
    let assetExporter = MDLAsset()
    // Create a new MDLAsset and add the mesh
    for (index, mesh) in meshes.enumerated() {
//        let outputURL = destinationFolderURL.appending(path: "RoomTest.obj")
        assetExporter.add(mesh)
//        do {
//            // Export to OBJ
//            try assetExporter.export(to: outputURL)
//            print("Exported to \(outputURL.path)")
//        } catch {
//            print("Failed to export: \(error.localizedDescription)")
//        }
    }
    
    let outputURL = destinationFolderURL.appending(path: "RoomTest.obj")
    do {
        print("Debug MDL Exported")
        try mdlAsset.export(to: outputURL)
    }
    catch {
        print("Failed to export: \(error.localizedDescription)")
    }
}
