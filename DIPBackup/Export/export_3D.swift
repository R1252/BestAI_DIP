//
//  export_3D.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/6/12.
//

import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO
import ModelIO

extension CustomViewController{
    func exportUSDZ(){
        let destinationURL = destinationFolderURL!.appending(path: "Room.usdz")
        let capturedRoomURL = destinationFolderURL!.appending(path: "RoomData.json")
        
        guard let structure = customCaptureView.savedStructure else {
            print("Debug - there are no savedStructure available")
            return
        }
        
        do {
            let jsonData = try JSONEncoder().encode(customCaptureView.savedStructure)
            try jsonData.write(to: capturedRoomURL)
            try structure.export(to: destinationURL, exportOptions: .mesh)
            
        } catch {
            print("Error = \(error)")
        }
    }
    
    func exportFloorPlan(){
        guard let structure = customCaptureView.savedStructure else {
            print("debug - no floor plan created due to no savedStructure")
            return
        }
        // AutoCAD
        _ = FloorPlan(structure: structure, defectAnchors: customCaptureView.defectAnchors, camAnchors: customCaptureView.camAnchors, folderURL: destinationFolderURL!)
    }
    
    func vertex(at index: UInt32, vertices: ARGeometrySource) -> SIMD3<Float> {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
        return vertex
    }
    
    func normal(at index: UInt32, normals: ARGeometrySource) -> SIMD3<Float> {
        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per normal.")
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        let normal = normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
        return normal
    }

    func face(at index: Int, faces: ARGeometryElement) -> [Int] {
        let indicesPerFace = faces.indexCountPerPrimitive
        let facesPointer = faces.buffer.contents()
        var vertexIndices = [Int]()
        for offset in 0..<indicesPerFace {
            let vertexIndexAddress = facesPointer.advanced(by: (index * indicesPerFace + offset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(Int(vertexIndexAddress.assumingMemoryBound(to: UInt32.self).pointee))
        }
        return vertexIndices
    }
    
//    func transformedTextureCoordinates(anchor : ARMeshAnchor, texture : TextureCloud) -> [vector_float2] {
//        let vertices = anchor.geometry.vertices
//        var textureCoordinates = [vector_float2](repeating: vector_float2(0, 0), count: vertices.count)
//        
//        let modelMatrix = anchor.transform
//        let camera = texture.camera
//        let size = texture.camera.imageResolution
//        
//        var meshColors = [vector_float4](repeating: vector_float4(0, 0, 0, 0), count: anchor.geometry.vertices.count)
////        var meshColors = [UIColor](repeating: UIColor.white, count: anchor.geometry.vertices.count)
//        
//        for vertexId in 0..<vertices.count {
//            let vertex = anchor.geometry.vertex(at: UInt32(vertexId))
////            let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
//            let vertex4 = vector_float4(vertex.0, vertex.1, vertex.2, 1)
//            let world_vertex4 = simd_mul(modelMatrix, vertex4)
//            let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
//            let pt = camera.projectPoint(world_vector3,
//                                         orientation: .landscapeRight,
//                                         viewportSize: CGSize(
//                                            width: CGFloat(size.width),
//                                            height: CGFloat(size.height)))
//            
//            if pt.x >= 0 && pt.x <= CGFloat(size.width) && pt.y >= 0 && pt.y <= CGFloat(size.height) {
//                let x = pt.x / size.width
//                let y = pt.y / size.height
//                let uvCoordinates = vector_float2(Float(x), 1.0 - Float(y))
////                print("debug uv :", vector_float2(u, v))
//                
//                if !allCoordinates.contains(uvCoordinates) {
//                    textureCoordinates[vertexId] = uvCoordinates
//                    print("New coordinates detected")
//                    do {
//                        let imageSampler = try CapturedImageSampler(frame: texture.arFrame)
//                        let frameColors = imageSampler.getColor(atX: x, y: y)
//                        meshColors[vertexId] = frameColors
//                    }
//                    catch {
//                        print("Error in getting colors")
//                    }
//                }
//                
//                else {
//                    textureCoordinates[vertexId] = vector_float2(0, 0)
//                    meshColors[vertexId] = vector_float4(0, 0, 0, 0)
//                    print("Old coordinates detected")
//                }
//            }
//            else {
//                // Handle out-of-bounds projection
//                print("Out of bounds")
//                textureCoordinates[vertexId] = vector_float2(0, 0)
//                meshColors[vertexId] = vector_float4(0, 0, 0, 0)
//            }
//        }
//        
//        allColors.append(contentsOf: meshColors)
//        return textureCoordinates
//    }
    
}

//extension ARMeshGeometry {
//    func transformedVertexBuffer(_ transform: simd_float4x4) -> [Float] {
//        var result = [Float]()
//        for index in 0..<vertices.count {
//            let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + vertices.stride * index)
//            let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
//            var vertexTransform = matrix_identity_float4x4
//            vertexTransform.columns.3 = SIMD4<Float>(vertex.0, vertex.1, vertex.2, 1)
//            let position = (transform * vertexTransform).position
//            result.append(position.x)
//            result.append(position.y)
//            result.append(position.z)
//        }
//        return result
//    }
//    
//    func transformedIndexBuffer(_ indexOffset: UInt32) -> [UInt32] {
//        var result = [UInt32]()
//        let indexCount = faces.count * faces.indexCountPerPrimitive
//        let indexPointer = faces.buffer.contents().bindMemory(to: UInt32.self, capacity: indexCount)
//        for i in 0..<indexCount {
//            result.append(indexPointer[i] + indexOffset)
//        }
//        return result
//    }
//}
