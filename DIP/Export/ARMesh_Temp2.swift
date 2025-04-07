//
//  ARMesh_Temp2.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/7/16.
//

import ARKit
import MetalKit

//extension CustomViewController {
//    func exportMesh(){
//        guard let frame = customCaptureView.captureSession.arSession.currentFrame else {
//            fatalError("Can't get ARFrame")
//        }
//        guard let device = MTLCreateSystemDefaultDevice() else {
//            fatalError("Can't create MTLDevice")
//        }
//        
//        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
//        
////        DispatchQueue.global().async { [self] in
////            var count = 0
////            for texture in textureCloud {
////                let image = getTextureImage(frame: texture.arFrame)!
////                saveImageToDocumentsDirectory(image: image, fileName: String(count))
////                count += 1
////            }
////        }
//        
//        let filename = destinationFolderURL!.appendingPathComponent("Room.obj")
//        let material = MDLMaterial(name: "material", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
//        
//        let asset = MDLAsset()
//        var allVertices = [Float]()
//        var allIndices = [UInt32]()
//        
//        var currentIndexOffset: UInt32 = 0
//        
////        print("meshAnchors.count " ,meshAnchors.count)
////        print("textureCloud.count " ,textureCloud.count)
//        
//        for anchor in meshAnchors {
//            let transformedVertices = anchor.geometry.transformedVertexBuffer(anchor.transform)
//            allVertices.append(contentsOf: transformedVertices)
//            
//            let indices = anchor.geometry.transformedIndexBuffer(currentIndexOffset)
//            allIndices.append(contentsOf: indices)
//            
//            currentIndexOffset += UInt32(anchor.geometry.vertices.count)
//            
////            for texture in textureCloud {
////                if texture.arFrame.anchors.contains(anchor) {
//////                    print("Match Found")
////                    let textureCoords = transformedTextureCoordinates(anchor: anchor, texture: texture)
////                    allCoordinates.append(contentsOf: textureCoords)
////                }
////            }
//        }
//        
//        let allocator = MTKMeshBufferAllocator(device: device)
//        let vertexData = Data(bytes: allVertices, count: allVertices.count * MemoryLayout<Float>.size)
//        let vertexBuffer = allocator.newBuffer(with: vertexData, type: .vertex)
//        
//        let indexData = Data(bytes: allIndices, count: allIndices.count * MemoryLayout<UInt32>.size)
//        let indexBuffer = allocator.newBuffer(with: indexData, type: .index)
//        
////        let textureData = Data(bytes: allCoordinates, count: allCoordinates.count * MemoryLayout<Float>.size)
////        let textureBuffer = allocator.newBuffer(with: textureData, type: .vertex)
//        
////        let colorData = Data(bytes: allColors, count: allColors.count * MemoryLayout<Float>.size)
////        let colorBuffer = allocator.newBuffer(with: colorData, type: .vertex)
//        
//        let vertexDescriptor = MDLVertexDescriptor()
//        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
////        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: 1)
////        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeColor, format: .float4, offset: 0, bufferIndex: 2)
//        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 3)
////        vertexDescriptor.layouts[1] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 2)
////        vertexDescriptor.layouts[2] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 4)
//        
//        let submesh = MDLSubmesh(indexBuffer: indexBuffer,
//                                 indexCount: allIndices.count,
//                                 indexType: .uInt32,
//                                 geometryType: .triangles,
//                                 material: material)
//        
//        let mdlMesh = MDLMesh(vertexBuffers: [vertexBuffer/*, textureBuffer, colorBuffer*/],
//                              vertexCount: allVertices.count / 3,
//                              descriptor: vertexDescriptor,
//                              submeshes: [submesh])
//        
//        asset.add(mdlMesh)
//        
//        do {
//            try asset.export(to: filename)
//            _ = destinationFolderURL!.appendingPathComponent("MyFirstMesh.mtl")
//        } catch {
//            print("Failed to write to file")
//        }
//    }
//    
//    func saveImageToDocumentsDirectory(image: UIImage, fileName: String) {
//        // Create the full file URL
//        let fileURL = destinationFolderURL!.appendingPathComponent("\(fileName).png")
//        
//        // Convert the UIImage to PNG data
//        guard let data = image.pngData() else {
//            print("Could not convert UIImage to PNG data")
//            return
//        }
//        
//        do {
//            // Write the data to the file
//            try data.write(to: fileURL)
//            print("Image saved successfully to \(fileURL)")
//            return
//        } catch {
//            print("Error saving image: \(error.localizedDescription)")
//            return
//        }
//    }
//    
//    func getTextureImage(frame: ARFrame) -> UIImage? {
//        let pixelBuffer = frame.capturedImage
//        let image = CIImage(cvPixelBuffer: pixelBuffer)
//        
//        let context = CIContext(options:nil)
//        guard let cameraImage = context.createCGImage(image, from: image.extent) else {return nil}
//        
//        return UIImage(cgImage: cameraImage)
//    }
//}
