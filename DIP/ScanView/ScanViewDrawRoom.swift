//
//  ScanViewDrawRoom.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//

import ARKit
import RoomPlan
import RealityKit

extension ScanView {
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
        
        // check if it has partitions
//        for wNode in wallNodes {
//            if wNode.name!.hasPrefix(surface.identifier.uuidString+"-"){
//                wNode.removeFromParentNode()
//                drawSurface(scene: roomView.scene!, surfaces: [surface])
//                print("Debug - wNode name ", wNode.name)
//            }
//        }
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
    
//    func drawSurface(scene: SCNScene, surfaces: [CapturedRoom.Surface]) {
//        var newNodes : [SCNNode] = []
//        for i in 0...surfaces.count-1 {
//            print("Debug - surface index", i, "wallNode.counts", wallNodes.count)
//            let surface = surfaces[i]
//            let surfaceDimensions = surface.dimensions
//            let surfaceTransform = surface.transform
//            let surfacePosition = surfaceTransform.position
//            let surfaceWidth = Float(surfaceDimensions.x)
//            let surfaceHeight = Float(surfaceDimensions.y)
//            for wallNode in wallNodes {
//                if isSurfacePositionOnWall(wall: wallNode, surface: surface) {
//                    print("Debug - Detected surface on wallNodes")
//                    // Wall bounding box and position calculations
//                    let wallDimensionsMax = wallNode.boundingBox.max
//                    let wallDimensionsMin = wallNode.boundingBox.min
//                    let wallPosition = wallNode.transform.position
//
//                    let wallWidth = CGFloat(wallDimensionsMax.x - wallDimensionsMin.x)
//                    let wallHeight = CGFloat(wallDimensionsMax.y - wallDimensionsMin.y)
//
//                    let wallHighest = wallPosition.y + Float(wallHeight)/2
//                    let surfaceHighest = surfacePosition.y + surfaceHeight/2
//
//                    // Assume there's always a upper wall
//                    let upperWallHeight = max(0,wallHighest - surfaceHighest)
//                    let lowerWallHeight = Float(wallHeight) - upperWallHeight - surfaceHeight
//
//                    // Wall endpoints and surface endpoints calculation
//                    let wallEndPoints = calculateWallEnds(transform: simd_float4x4(wallNode.transform), xDim: Float(wallWidth))
//                    let wallLeftEdge = simd_float3(x: wallEndPoints.first!.x, y: wallPosition.y, z: wallEndPoints.first!.y)
//                    let wallRightEdge = simd_float3(x: wallEndPoints.last!.x, y: wallPosition.y, z: wallEndPoints.last!.y)
//
//                    let surfEndPoints = calculateWallEnds(transform: surfaceTransform, xDim: surfaceWidth)
//                    let surfLeftEdge = simd_float3(x: surfEndPoints.first!.x, y: wallPosition.y, z: surfEndPoints.first!.y)
//                    let surfRightEdge = simd_float3(x: surfEndPoints.last!.x, y: wallPosition.y, z: surfEndPoints.last!.y)
//
//                    // Calculate new left and right wall positions
//                    let leftWallPosition = SCNVector3(
//                        x: wallLeftEdge.x + (-wallLeftEdge.x + surfLeftEdge.x) / 2,
//                        y: wallPosition.y,
//                        z: wallLeftEdge.z - (wallLeftEdge.z - surfLeftEdge.z) / 2
//                    )
//
//                    let rightWallPosition = SCNVector3(
//                        x: wallRightEdge.x - (wallRightEdge.x - surfRightEdge.x) / 2,
//                        y: wallPosition.y,
//                        z: wallRightEdge.z + (-wallRightEdge.z + surfRightEdge.z) / 2
//                    )
//
//                    let upperWallPosition = SCNVector3(
//                        x: surfacePosition.x,
//                        y: surfaceHighest + upperWallHeight/2,
//                        z: surfacePosition.z
//                    )
//
//                    let lowerWallPosition = SCNVector3(
//                        x: surfacePosition.x,
//                        y: lowerWallHeight/2,
//                        z: surfacePosition.z
//                    )
//
//                    // Wall width calculations
//                    let leftWallWidth = CGFloat(sqrt(pow((wallLeftEdge.x - surfLeftEdge.x), 2) + pow((wallLeftEdge.z - surfLeftEdge.z), 2)))
//                    let rightWallWidth = CGFloat(sqrt(pow((surfRightEdge.x - wallRightEdge.x), 2) + pow((surfRightEdge.z - wallRightEdge.z), 2)))
//
//                    // Debug information for checking error
////                    print("Debug \nWallWidth", wallWidth,"\nleftWallWidth", leftWallWidth , "\nrightWallWidth", rightWallWidth, "\nsurfaceWidth", surfaceWidth, "\nerror margin", wallWidth - (leftWallWidth + rightWallWidth + CGFloat(surfaceWidth)))
//
//                    // Create the left and right wall segments
//                    let leftWallBox = SCNBox(width: leftWallWidth, height: wallHeight, length: 0.0, chamferRadius: 0.0)
//                    let leftWallNode = SCNNode(geometry: leftWallBox)
//                    leftWallNode.position = leftWallPosition
//                    leftWallNode.eulerAngles = wallNode.eulerAngles
////                    leftWallNode.name = wallNode.name?.appending("-l")
//
//                    let rightWallBox = SCNBox(width: rightWallWidth, height: wallHeight, length: 0.0, chamferRadius: 0.0)
//                    let rightWallNode = SCNNode(geometry: rightWallBox)
//                    rightWallNode.position = rightWallPosition
//                    rightWallNode.eulerAngles = wallNode.eulerAngles
////                    rightWallNode.name = wallNode.name?.appending("-r")
//
//                    let lowerWallBox = SCNBox(width: CGFloat(surfaceWidth), height: CGFloat(lowerWallHeight), length: 0.0, chamferRadius: 0.0)
//                    let lowerWallNode = SCNNode(geometry: lowerWallBox)
//                    lowerWallNode.position = lowerWallPosition
//                    lowerWallNode.eulerAngles = SCNVector3(surfaceTransform.eulerAngles)
////                    lowerWallNode.name = wallNode.name?.appending("-lo")
//
//                    let upperWallBox = SCNBox(width: CGFloat(surfaceWidth), height: CGFloat(upperWallHeight), length: 0.0, chamferRadius: 0.0)
//                    let upperWallNode = SCNNode(geometry: upperWallBox)
//                    upperWallNode.position = upperWallPosition
//                    upperWallNode.eulerAngles = SCNVector3(surfaceTransform.eulerAngles)
////                    upperWallNode.name = wallNode.name?.appending("-up")
//
//                    // Debug
////                    leftWallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
////                    rightWallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red
////                    upperWallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.green
////                    lowerWallNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//
//                    // Create the surface object and position it
//                    // temporary set to wall height
//                    let surfaceBox = SCNBox(width: CGFloat(surfaceWidth), height: CGFloat(surfaceHeight), length: 0.0, chamferRadius: 0.0)
//                    let surfaceNode = SCNNode(geometry: surfaceBox)
//                    surfaceNode.transform = SCNMatrix4(surfaceTransform)
//                    surfaceNode.position.y = wallNode.position.y
//                    surfaceNode.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.4)
//
//                    newNodes = [leftWallNode, rightWallNode, upperWallNode, lowerWallNode, surfaceNode]
//
//                    for node in newNodes {
//                        scene.rootNode.addChildNode(node)
//                        // add label so that we can delete later
//                        node.name = surface.identifier.uuidString + "-"
//                        highlightNode(node)
//                    }
//
//                    for node in newNodes {
//                        print("Debug - node.name", node.name)
//                    }
//
//                    // Add the new nodes to the scene
////                    scene.rootNode.addChildNode(surfaceNode)
////                    scene.rootNode.addChildNode(leftWallNode)
////                    scene.rootNode.addChildNode(rightWallNode)
////                    scene.rootNode.addChildNode(upperWallNode)
////                    scene.rootNode.addChildNode(lowerWallNode)
//
//                    // Append new walls to the list for future checks
////                    newWallNodes.append(leftWallNode)
////                    newWallNodes.append(rightWallNode)
//
//                    // Remove the old wall
//                    wallNode.removeFromParentNode()
//                    // Remove old wall from list [Might be uneccessary]
////                    wallNodes.remove(at: index)
//
//                    // Highlight the new wall sections
////                    highlightNode(leftWallNode)
////                    highlightNode(rightWallNode)
////                    highlightNode(upperWallNode)
////                    highlightNode(lowerWallNode)
//                }
//            }
//            // append left and right wall
//            if !newNodes.isEmpty{
//                for i in 0...newNodes.count - 1{
//                    let node = newNodes[i]
//                    wallNodes.append(node)
//                }
//            }
//        }
//    }
    
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
    
    func isSurfacePositionOnWall(wall: SCNNode, surface: CapturedRoom.Surface) -> Bool {
        // Wall bounding box and position calculations
        let wallDimensionsMax = wall.boundingBox.max
        let wallDimensionsMin = wall.boundingBox.min
        let wallPosition = wall.transform.position
        let wallWidth = CGFloat(wallDimensionsMax.x - wallDimensionsMin.x)
        let surfacePosition = surface.transform.position
        
        // Wall endpoints and surface endpoints calculation
        let wallEndPoints = calculateWallEnds(transform: simd_float4x4(wall.transform), xDim: Float(wallWidth))
        let wallLeftEdge = simd_float3(x: wallEndPoints.first!.x, y: wallPosition.y, z: wallEndPoints.first!.y)
        let wallRightEdge = simd_float3(x: wallEndPoints.last!.x, y: wallPosition.y, z: wallEndPoints.last!.y)
        
        let surfEndPoints = calculateWallEnds(transform: surface.transform, xDim: surface.dimensions.x)
        let surfLeftEdge = simd_float3(x: surfEndPoints.first!.x, y: surfacePosition.y, z: surfEndPoints.first!.y)
        let surfRightEdge = simd_float3(x: surfEndPoints.last!.x, y: surfacePosition.y, z: surfEndPoints.last!.y)
        
        let halfWallHeight = (wallDimensionsMax.y - wallDimensionsMin.y) / 2.0
        
        // Window is placed on the XZ plane of the wall (Y axis for height)
        let isWithinXBounds = (surfRightEdge.x <= wallRightEdge.x) &&
                              (surfLeftEdge.x >= wallLeftEdge.x)
        
        let isWithinYBounds = (surfacePosition.y >= wallPosition.y - halfWallHeight) &&
                              (surfacePosition.y <= wallPosition.y + halfWallHeight)
        
        let isWithinZBounds = (surfRightEdge.z >= wallRightEdge.z) &&
                              (surfLeftEdge.z <= wallLeftEdge.z)
        
        // works but infinitely divides
//        let isWithinXBounds = (surfacePosition.x <= wallRightEdge.x) &&
//                              (surfacePosition.x >= wallLeftEdge.x)
//
//        let isWithinYBounds = (surfacePosition.y >= wallPosition.y - halfWallHeight) &&
//                              (surfacePosition.y <= wallPosition.y + halfWallHeight)
//
//        let isWithinZBounds = (surfacePosition.z <= wallRightEdge.z) &&
//                              (surfacePosition.z >= wallLeftEdge.z)
        
//        print("Debug - surfRightEdge", surfRightEdge)
//        print("Debug - wallRightEdge", wallRightEdge)
//        print("Debug - surfLeftEdge", surfLeftEdge)
//        print("Debug - wallLeftEdge", wallLeftEdge)
//        print("Debug - surfRightEdge", surfRightEdge, "- wallRightEdge", wallRightEdge)
//        print("Debug - surfLeftEdge", surfLeftEdge, "- wallLeftEdge", wallLeftEdge)
//        print("Debug - xBounds", isWithinXBounds, "- zBounds", isWithinZBounds, "\n")
        // If the window's position overlaps with the wall's position, return true
        return isWithinXBounds && isWithinYBounds && isWithinZBounds
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
