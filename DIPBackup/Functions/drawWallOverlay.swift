//
//  drawWallOverlay.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/3/18.
//

import ARKit
import RoomPlan
import RealityKit

extension CustomCaptureView {
    func drawPlanes(scene:SCNScene, surface: CapturedRoom.Surface){
        let dimensions = surface.dimensions
        let box = SCNBox(width: CGFloat(dimensions.x), 
                         height: CGFloat(dimensions.y),
                         length: CGFloat(dimensions.z),
                         chamferRadius: 0.0)
        let node = SCNNode(geometry: box)
        node.transform = SCNMatrix4(surface.transform)
        node.name = surface.identifier.uuidString
        if surface.category == CapturedRoom.Surface.Category.wall {
            highlightNode(node)
            wallNodes.append(node)
        }
        else if surface.category == CapturedRoom.Surface.Category.floor {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        }
        scene.rootNode.addChildNode(node)
    }
    
    func updatePlanes(scene: SCNScene, surface: CapturedRoom.Surface) {
        guard let node = scene.rootNode.childNodes.first(where:{$0.name == surface.identifier.uuidString}) else {
            print("Debug - node not found \(surface.category)", surface.identifier.uuidString)
            return
        }
        
        node.childNodes.forEach({$0.removeFromParentNode()})
        
        let dimensions = surface.dimensions
        var length = CGFloat(dimensions.z)
        var nodeDiffuse = UIColor.white
        
        if [.door(isOpen: true), .door(isOpen: false), .window, .opening].contains(surface.category) {
            nodeDiffuse = UIColor.darkGray.withAlphaComponent(0.5)
            length = 0.1
        }
        
        let box = SCNBox(width: CGFloat(dimensions.x), height: CGFloat(dimensions.y), length: length, chamferRadius: 0.0)
        node.geometry = box
        node.geometry?.firstMaterial?.diffuse.contents = nodeDiffuse
        node.transform = SCNMatrix4(surface.transform)
        highlightNode(node)
        
        // add animation
    }
    
    func drawSurface(scene: SCNScene, surface: CapturedRoom.Surface) {
        let surfaceBox = SCNBox(width: CGFloat(surface.dimensions.x),
                                height: CGFloat(surface.dimensions.y),
                                length: 0.1, chamferRadius: 0.0)
        let surfaceNode = SCNNode(geometry: surfaceBox)
        surfaceNode.transform = SCNMatrix4(surface.transform)
        surfaceNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray.withAlphaComponent(0.5)
        surfaceNode.name = surface.identifier.uuidString
//                    surfaceNode.geometry?.firstMaterial?.fillMode = .lines
        highlightNode(surfaceNode)
        scene.rootNode.addChildNode(surfaceNode)
    }
    
    func createLineNode(fromPos origin: SCNVector3, toPos destination: SCNVector3) -> SCNNode {
        let line = lineFrom(vector: origin, toVector: destination)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor.black
        line.materials = [planeMaterial]
        
        return lineNode
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        // change width of element
        element.pointSize = 10.0
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    func highlightNode(_ node: SCNNode) {
        let (min, max) = node.boundingBox
        let zCoord : Float = 0
        let topLeft = SCNVector3Make(min.x, max.y, zCoord)
        let bottomLeft = SCNVector3Make(min.x, min.y, zCoord)
        let topRight = SCNVector3Make(max.x, max.y, zCoord)
        let bottomRight = SCNVector3Make(max.x, min.y, zCoord)
        
        let bottomSide = createLineNode(fromPos: bottomLeft, toPos: bottomRight)
        let leftSide = createLineNode(fromPos: bottomLeft, toPos: topLeft)
        let rightSide = createLineNode(fromPos: bottomRight, toPos: topRight)
        let topSide = createLineNode(fromPos: topLeft, toPos: topRight)
        
        [bottomSide, leftSide, rightSide, topSide].forEach {
            $0.name = "kHighlightingNode" // Whatever name you want so you can unhighlight later if needed
            node.addChildNode($0)
        }
    }
    
    func nodeBehindCamera(node: SCNNode, arCam: simd_float3) -> Bool {
        // Get wall node position
        let position = node.position
        // Calculate the vector from the camera to the wall node
        let toNode = SCNVector3(
            position.x - arCam.x,
            position.y - arCam.y,
            arCam.z - position.z 
            // flipped because positive z is towards user instead of away from user
        )
        // Calculate the dot product between the camera's forward vector and the vector to the wall node
        let dotProduct = arCam.x * toNode.x + arCam.y * toNode.y + arCam.z * toNode.z
        // If the dot product is negative, the wall is behind the camera
        return dotProduct < 0
    }
}

func calculateWallEnds(transform: simd_float4x4, xDim: Float) -> [SIMD2<Float>] {
    // xDim = xDimension
    let position = transform.position
    let angle = transform.eulerAngles.y
    let width = xDim/2
    let dx = width*cos(angle)
    let dz = width*sin(angle)
    let pointA : SIMD2<Float> = [position.x - dx,position.z + dz]
    let pointB : SIMD2<Float> = [position.x + dx,position.z - dz]

    return [pointA,pointB]
}

