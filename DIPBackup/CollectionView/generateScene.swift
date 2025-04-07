//
//  generateScene.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/6/20.
//
import ARKit
import SceneKit
import RoomPlan

extension ModelViewController {
    func generateScene(model: CapturedStructure) {
        guard let room = selectedRoom else {
            print("Debug - no RoomScanned was given")
            return
        }
        let bounds_3d = room.bounds_3d
        
        nodes.removeAll()
        let heightAdjustment = model.floors.first!.transform.position.y
        let surfaces = model.walls + model.doors + model.windows + model.openings + model.floors
        
        // Process surfaces and objects in parallel
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        DispatchQueue.global().async { [self] in
            getAllNodes(for: surfaces, heightAdjustment: heightAdjustment)
            getAllNodes(for: model.objects, heightAdjustment: heightAdjustment)
            getAllNodes(for: bounds_3d, heightAdjustment: heightAdjustment)
            createImageHolder(csvData: room.csvData, heightAdjustment: heightAdjustment)
            dispatchGroup.leave()
        }
    }
    
    func getAllNodes(for surfaces: [CapturedRoom.Surface], heightAdjustment: Float) {
        for surface in surfaces {
            let width = CGFloat(surface.dimensions.x)
            let height = CGFloat(surface.dimensions.y)
            let node = SCNNode()
            var length = 0.11
            var boxMaterial = SCNMaterial()
            
            switch surface.category {
            case .door:
                node.name = "door"
                boxMaterial = doorMaterial
            case .wall:
                node.name = "immovable wall"
                boxMaterial = wallMaterial
                length = 0.1
            case .floor:
                node.name = "immovable"
                boxMaterial = floorMaterial
            case .window:
                node.name = "immovable"
                boxMaterial = windowMaterial
            case .opening:
                node.name = "immovable"
                boxMaterial = doorMaterial
            default:
                node.name = "immovable"
            }
            
            let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0.0)
            box.materials = [boxMaterial]
            
            node.geometry = box
            node.transform = SCNMatrix4(surface.transform)
            node.position.y -= heightAdjustment
            sceneView.scene?.rootNode.addChildNode(node)
            nodes.append(node)
        }
    }
    
    func getAllNodes(for positions: [simd_float3], heightAdjustment: Float) {
        for position in positions {
            let node = SCNNode()
            let sphere = SCNSphere(radius: 0.1)
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.red
            sphere.materials = [material]
            node.geometry = sphere
            node.position = SCNVector3(position)
            node.position.y -= heightAdjustment
            node.name = "defects"
            sceneView.scene?.rootNode.addChildNode(node)
            nodes.append(node)
        }
    }
    
    func getAllNodes(for objects: [CapturedRoom.Object], heightAdjustment: Float) {
        var modelName = ""
        var objectNodes: [SCNNode] = []
        
        for object in objects {
            let category = object.category
            switch category {
                case .bed: modelName = "Bed"
                case .storage: modelName = "Storage"
                case .refrigerator: modelName = "Refrigerator"
                case .stove: modelName = "Stove_Temp"
                case .sink: modelName = "Sink"
                case .washerDryer: modelName = "Washer_Dryer"
                case .toilet: modelName = "Toilet"
                case .bathtub: modelName = "Toilet_Bathtub"
                case .oven: modelName = "Oven"
                case .dishwasher: modelName = "Dishwasher"
                case .table: modelName = "Table_Dining"
                case .sofa: modelName = "Chair_Couch"
                case .chair: modelName = "Chair_Dining"
                case .fireplace: modelName = "Fireplace"
                case .television: modelName = "Television"
                case .stairs: modelName = "Stairs"
                @unknown default: modelName = "Square"
            }
            
            let node = addModel(modelName: modelName)
            let nodeDimensions = subtract(node.boundingBox.max, node.boundingBox.min)
            let nodeScale = SCNVector3(object.dimensions.x / nodeDimensions.x,
                                       object.dimensions.y / nodeDimensions.y,
                                       object.dimensions.z / nodeDimensions.z)
            node.transform = SCNMatrix4(object.transform)
            node.position.y -= (heightAdjustment + nodeDimensions.y / 2 * nodeScale.y)
            node.scale = nodeScale
            
            let bound = SCNVector3(x: node.boundingBox.max.x + node.boundingBox.min.x,
                                   y: 0,
                                   z: node.boundingBox.max.z + node.boundingBox.min.z)
            node.pivot = SCNMatrix4MakeTranslation(bound.x/2, bound.y, bound.z/2)
            
            objectNodes.append(node)
            self.sceneView.scene?.rootNode.addChildNode(node)
            self.nodes.append(node)
        }
    }
    
    func addModel(modelName: String) -> SCNNode{
        let nilNode = SCNNode()
        let modelPath = "FurnitureAssets.scnassets/\(modelName)"
        
        guard let modelUrl = Bundle.main.url(forResource: modelPath, withExtension: "usdz") else {
            print("Debug - Model \(modelName) not found.")
            return nilNode
        }
        
        do {
            let furnitureScene = try SCNScene(url: modelUrl, options: [.convertToYUp: true])
            
            guard let furnitureNode = furnitureScene.rootNode.childNodes.first else {
                print("No child nodes found in the model.")
                return nilNode
            }
            
            let furnitureName = String("f_"+modelName)
            furnitureNode.name = furnitureName
            furnitureNode.transform = SCNMatrix4Identity
            return furnitureNode
        } catch {
            print("Debug Error: ", error)
            return nilNode
        }
    }
    
    func createImageHolder(csvData: CSVData, heightAdjustment: Float) {
        guard let bounds_3d = csvData.bounds_3d else {
            print("Debug - unable to get bounds_3d from csvData")
            return
        }
        
        for (i,image) in self.images.enumerated() {
            var width : Float = 0.0
            let xDiff = abs(bounds_3d[4*i].x - bounds_3d[4*i+2].x)
            let zDiff = abs(bounds_3d[4*i].z - bounds_3d[4*i+2].z)
            
            if xDiff >= zDiff {
                width = xDiff
            } else {
                width = zDiff
            }
            
            let height = abs(bounds_3d[4*i].y - bounds_3d[4*i+2].y)
            let transform = defectTransform[i]
            
            let box = SCNBox(width: CGFloat(width), height: 0.05, length: CGFloat(height), chamferRadius: 0)
            
            let material = SCNMaterial()
            material.isDoubleSided = false
            material.diffuse.contents = image
            box.materials = [material]
            let node = SCNNode(geometry: box)
            node.transform = SCNMatrix4(transform)
            node.position.y -= heightAdjustment
            
            node.eulerAngles.x = roundToNearestAngle(angle_rad: node.eulerAngles.x)
            node.eulerAngles.z = roundToNearestAngle(angle_rad: node.eulerAngles.z)
            self.sceneView.scene?.rootNode.addChildNode(node)
        }
    }
    
    func roundToNearestAngle(angle_rad: Float) -> Float {
        let angle = angle_rad * 180/(.pi)
        // Normalize the angle to the range 0 - 360 degrees
        let normalizedAngle = (angle.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        
        // Define possible positive angles
        let possibleAngles : [Float] = [0, 90, 180, 270, 360]
        
        // Find the closest angle by comparing absolute differences
        var closestAngle = possibleAngles.min(by: { abs(normalizedAngle - $0) < abs(normalizedAngle - $1) }) ?? 0
        
        // change from degrees to rad
        closestAngle = closestAngle * .pi / 180
        
        // If the original angle was negative, adjust the sign of the result
        return angle < 0 ? -closestAngle : closestAngle
    }


    
//    func getAllNodes(for objects: [CapturedRoom.Object], heightAdjustment: Float) {
//        var modelName = ""
//        var objectNodes : [SCNNode] = []
//        
//        objects.forEach { object in
//            let category = object.category
//            switch category {
//            case .bed: modelName = "Bed"
//            case .storage: modelName = "Storage"
//            case .refrigerator: modelName = "Refrigerator"
//            case .stove: modelName = "Stove"
//            case .sink: modelName = "Sink"
//            case .washerDryer: modelName = "Washer_Dryer"
//            case .toilet: modelName = "Toilet"
//            case .bathtub: modelName = "Toilet_Bathtub"
//            case .oven: modelName = "Stove"
//            case .dishwasher: modelName = "Dishwasher"
//            case .table: modelName = "Table_Dining"
//            case .sofa: modelName = "Sofa"
//            case .chair: modelName = "Chair_Dining"
//            case .fireplace: modelName = "Fireplace"
//            case .television: modelName = "Television"
//            case .stairs: modelName = "Stairs"
//            @unknown default: modelName = "Square"
//            }
//            // box are for debugging
//            let box = SCNBox(width: CGFloat(object.dimensions.x), height: CGFloat(object.dimensions.y), length: CGFloat(object.dimensions.z), chamferRadius: 0.0)
//            box.materials = [windowMaterial]
//            let debugBox = SCNNode(geometry: box)
//            sceneView.scene?.rootNode.addChildNode(debugBox)
//            debugBox.transform = SCNMatrix4(object.transform)
//            debugBox.position.y -= heightAdjustment
//            
//            let node = addModel(modelName: modelName)
//            let nodeDimensions = subtract(node.boundingBox.max, node.boundingBox.min)
//            let nodeScale = SCNVector3(object.dimensions.x/nodeDimensions.x,
//                                       object.dimensions.y/nodeDimensions.y,
//                                       object.dimensions.z/nodeDimensions.z)
//            node.transform = SCNMatrix4(object.transform)
//            node.position.y -= (heightAdjustment + nodeDimensions.y/2 * nodeScale.y)
//            node.scale = nodeScale
//            let bound = SCNVector3(x: node.boundingBox.max.x +  node.boundingBox.min.x,
//                                       y: 0,
//                                       z: node.boundingBox.max.z +  node.boundingBox.min.z)
//            node.pivot = SCNMatrix4MakeTranslation(bound.x / 2,
//                                                   bound.y / 2,
//                                                   bound.z / 2)
//            objectNodes.append(node)
//            sceneView.scene?.rootNode.addChildNode(node)
//            nodes.append(node)
//        }
//    }
    
//    func addModel(modelName: String) -> SCNNode{
//        var node = SCNNode()
//        let modelPath = "FurnitureAssets.scnassets/\(modelName)"
//        
//        guard let modelUrl = Bundle.main.url(forResource: modelPath, withExtension: "usdz") else {
//            print("Model not found.")
//            return node
//        }
//        
//        let mdlAsset = MDLAsset(url: modelUrl)
//        mdlAsset.loadTextures()
//        let asset = mdlAsset.object(at: 0) // extract first object
//        node = SCNNode(mdlObject: asset)
//        node.name = String("f_"+modelName)
//        return node
//    }
    
    func toggleHeights() {
        if dimension == 3 {
            for node in nodes {
                originalHeights[node] = node.simdTransform.columns.1.y
                originalY[node] = node.position.y
                node.simdTransform.columns.1.y = 0.01
                node.position.y = 0
            }
        } else {
            for (node, originalHeight) in originalHeights {
                node.simdTransform.columns.1.y = originalHeight
                node.position.y = originalY[node]!
            }
        }
    }
}

func subtract(_ vector1 : SCNVector3, _ vector2 : SCNVector3) -> SCNVector3{
    let dx = abs(vector1.x - vector2.x)
    let dy = abs(vector1.y - vector2.y)
    let dz = abs(vector1.z - vector2.z)
    
    let newVector = SCNVector3(dx,dy,dz)
    return newVector
}

func getDistance(_ vector1 : simd_float3, _ vector2 : simd_float3) -> Float{
    let dx = abs(vector1.x - vector2.x)
    let dy = abs(vector1.y - vector2.y)
    let dz = abs(vector1.z - vector2.z)
    
    let dist = sqrt(dx*dx+dy*dy+dz*dz)
    return dist
}
