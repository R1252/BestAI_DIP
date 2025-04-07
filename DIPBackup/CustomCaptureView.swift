//
//  CustomCaptureView.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/2/21.
//
import UIKit
import RealityKit
import RoomPlan
import ARKit

class CustomCaptureView: ARView, RoomCaptureSessionDelegate {
    var roomBuilder = RoomBuilder(options: [.beautifyObjects])
    var structureBuilder = StructureBuilder(options: [.beautifyObjects])
    var isScanning : Bool?
    var statusLabelText : String?
    var captureSession: RoomCaptureSession = RoomCaptureSession()
//    var previousCaptureSession : RoomCaptureSession?
//    var previousWorldMap : ARWorldMap?
    var firstScan = true
//    var delegate: RoomCaptureViewDelegate?
    
    var savedStructure : CapturedStructure?
    var savedRooms : [CapturedRoom] = []
    var surfaceInRoom : [CapturedRoom.Surface] = []
    var wallNodes : [SCNNode] = []
    var wallPoints : [SIMD2<Float>] = []
    
    var defectAnchors : [ARAnchor] = []
    var camAnchors : [ARAnchor] = []
    var anchorNumberForIdentification = 0
    
    required init(frame: CGRect){
        super.init(frame: frame)
        initSession()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder){
        super.init(coder: decoder)
        initSession()
    }
    
    func initSession(){
        self.cameraMode = .ar
        captureSession.delegate = self
        print("Session Init again")
    }
    
    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        print("sessionStartedAgain")
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.sceneReconstruction = .meshWithClassification
        arConfiguration.planeDetection = [.vertical,.horizontal]
        arConfiguration.environmentTexturing = .automatic
//        if savedRooms.isEmpty {
//            statusLabelText = "Starting Room Capture Session!"
////            print("Debug Starting Room Capture Session!")
//        }
//        else {
//            statusLabelText = "Relocalizing Room Capture Session!Ω"
////            print("Debug Relocalizing Room Capture Session!")
//        }
        
        if firstScan {
            statusLabelText = "Starting Room Capture Session!"
            self.captureSession.arSession.run(arConfiguration/*, options: [.resetTracking]*/)
            self.session = captureSession.arSession
//            print("Debug Starting Room Capture Session!")
        }
        else {
            statusLabelText = "Relocalizing Room Capture Session!"
//            captureSession = previousCaptureSession!
            
            self.session = captureSession.arSession
            cleanScene()
            
//            let arWorldMap = previousWorldMap

            // run ARKit relocalization
//            let arWorldTrackingConfig = ARWorldTrackingConfiguration()
//            arWorldTrackingConfig.initialWorldMap = arWorldMap
            
//            self.captureSession.arSession.run(arWorldTrackingConfig)

            // Wait for relocalization to complete
            // start 2nd scan
            self.captureSession.run(configuration: configuration)
            print("Debug Relocalizing Room Capture Session!")
        }
        isScanning = true
    }
    
    func captureSession(_ session: RoomCaptureSession, didUpdate: CapturedRoom) {
        DispatchQueue.main.async { [self] in
            Task {
                if savedRooms.isEmpty {
                    savedStructure = try await structureBuilder.capturedStructure(from: [didUpdate])
                }
                else {
                    savedRooms.append(didUpdate)
                    savedStructure = try await structureBuilder.capturedStructure(from: savedRooms)
                    savedRooms.removeLast()
                }
                roomFloor = savedStructure?.floors.first
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        if firstScan {
            DispatchQueue.main.async { [self] in
                Task {
                    var planes : [CapturedRoom.Surface] = []
                    var wallOpenings : [CapturedRoom.Surface] = []
                    //                if savedRooms.isEmpty {
                    planes = room.floors + room.walls // floors aren't drawn for some reason
                    wallOpenings = room.windows + room.doors + room.openings
                    //                }
                    //                else {
                    //                    savedRooms.append(room)
                    //                    savedStructure = try await structureBuilder.capturedStructure(from: savedRooms)
                    //                    savedRooms.removeLast()
                    //
                    //                    planes = savedStructure!.floors + savedStructure!.walls // floors aren't drawn for some reason
                    //                    wallOpenings = savedStructure!.windows + savedStructure!.doors + savedStructure!.openings
                    //                }
                    
                    for plane in planes {
                        drawPlanes(scene: roomView.scene!, surface: plane)
                    }
                    
                    for wallOpening in wallOpenings {
                        drawSurface(scene: roomView.scene!, surface: wallOpening)
                        surfaceInRoom.append(wallOpening)
                    }
                    
                    //            if !surfaceInRoom.isEmpty {
                    //                drawSurface(scene: roomView.scene!, surfaces: surfaceInRoom)
                    //            }
                    //            for floor in room.floors {
                    ////                drawFloor(scene: roomView.scene!, floor: floor)
                    //                drawPlanes(scene: roomView.scene!, surface: floor)
                    //            }
                    //            // draw walls
                    //            for wall in room.walls {
                    ////                drawWallBorders(scene: roomView.scene!, wall: wall)
                    //                drawPlanes(scene: roomView.scene!, surface: wall)
                    //            }
                    
                    //            for window in room.windows {
                    //                print("Debug - detected window")
                    //                surfaceInRoom.append(window)
                    //            }
                    //            for door in room.doors {
                    //                print("Debug - detected door")
                    //                surfaceInRoom.append(door)
                    //            }
                    //            for opening in room.openings {
                    //                print("Debug - detected opening")
                    //                surfaceInRoom.append(opening)
                    //            }
                }
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        if firstScan {
            DispatchQueue.main.async { [self] in
                Task {
                    var updatedSurface : [CapturedRoom.Surface] = []
                    //                if savedRooms.isEmpty {
                    updatedSurface = room.floors + room.walls + room.windows + room.doors + room.openings
                    //                }
                    //                else {
                    //                    savedRooms.append(room)
                    //                    savedStructure = try await structureBuilder.capturedStructure(from: savedRooms)
                    //                    savedRooms.removeLast()
                    //                    updatedSurface = savedStructure!.floors + savedStructure!.walls + savedStructure!.windows + savedStructure!.doors + savedStructure!.openings
                    //                }
                    
                    for surface in updatedSurface {
                        updatePlanes(scene: roomView.scene!, surface: surface)
                    }
                }
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        if firstScan {
            var deletedSurface : [CapturedRoom.Surface] = []
            let childNodes = roomView.scene!.rootNode.childNodes
            
            DispatchQueue.main.async { [self] in
                Task {
                    //                if savedRooms.isEmpty {
                    deletedSurface = room.floors + room.walls + room.windows + room.doors + room.openings
                    //                }
                    //                else {
                    //                    savedRooms.append(room)
                    //                    savedStructure = try await structureBuilder.capturedStructure(from: savedRooms)
                    //                    savedRooms.removeLast()
                    //
                    //                    deletedSurface = savedStructure!.floors + savedStructure!.walls + savedStructure!.windows + savedStructure!.doors + savedStructure!.openings
                    //                }
                    for surface in deletedSurface {
                        // wall
                        if surface.category == CapturedRoom.Surface.Category.wall {
                            for (index,node) in wallNodes.enumerated(){
                                if node.name!.hasPrefix(surface.identifier.uuidString) {
                                    node.removeFromParentNode()
                                    wallNodes.remove(at: index)
                                    print("Debug - removed wall")
                                }
                            }
                        }
                        // other surfaces
                        else {
                            guard let node = childNodes.filter({$0.name == surface.identifier.uuidString}).first else {
                                return
                            }
                            node.removeFromParentNode()
                            print("Debug - removed",surface.category)
                        }
                    }
                }
            }
        }
    }

    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        if isScanning == true {
            DispatchQueue.main.async { [self] in
                switch instruction {
                case.normal:
                    statusLabelText = "正常掃描"
                case .lowTexture:
                    statusLabelText = "紋理較少"
                case .moveAwayFromWall:
                    statusLabelText = "遠離牆壁"
                case .moveCloseToWall:
                    statusLabelText = "靠近牆壁"
                case.slowDown:
                    statusLabelText = "慢一點"
                case.turnOnLight:
                    statusLabelText = "暗堂煞, 建議加燈"
                @unknown default:
                    statusLabelText = "idk bro"
                }
            }
        }
    }
    // this is where scan ends
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (Error)?) {
        if firstScan {
            Task {
                statusLabelText = "captureSession ended"
                isScanning = false
                let room = try! await roomBuilder.capturedRoom(from: data)
                if (error == nil){
                    savedRooms.append(room)
                    print("Debug - savedRoom count, finished", savedRooms.count)
                    
                    guard let structure = savedStructure else {
                        print("Debug - no walls detected")
                        return
                    }
                    // create wall points
                    let walls = structure.walls
                    
                    wallPoints = []
                    for wall in walls {
                        let endPoints = calculateWallEnds(transform: wall.transform, xDim: wall.dimensions.x)
                        wallPoints.append(contentsOf: interpolateBetweenPoints(start: endPoints[0], end: endPoints[1]))
                    }
                    // debugging for wallPoints
                    //                let wallHalfHeight = walls.first!.transform.position.y
                    //                for point_simd2 in wallPoints {
                    //                    let point = simd_float3(x: point_simd2.x, y: wallHalfHeight, z: point_simd2.y)
                    //                    csvData.bounds_3d.append(point)
                    //                }
                }
                else {
                    statusLabelText = " \(String(describing: error))"
                }
                previousScene = roomView.scene
            }
            //        previousCaptureSession = session
            //        captureSession.arSession.getCurrentWorldMap { worldMap, error in
            //            self.previousWorldMap = worldMap
            //
            //            if error != nil{
            //                print("Debug getWorldMap error ", error.debugDescription)
            //            }
            //        }
            session.stop(pauseARSession: false)
            firstScan = false
        }
    }
    
    func cleanScene(){
        roomView.scene?.rootNode.childNodes.forEach { node in
            node.removeFromParentNode()
        }
        wallNodes.removeAll()
        surfaceInRoom.removeAll()
    }
    
    func cleanSceneDemo () {
        let tolerance : Float = 0.1
        // nNode = newNode || oNode = oldNode
        roomView.scene?.rootNode.childNodes.forEach { nNode in
            if previousScene == nil {
                nNode.removeFromParentNode()
            }
            else {
                previousScene?.rootNode.childNodes.forEach { oNode in
                    if abs(nNode.position.x - oNode.position.x) <= tolerance &&
                        abs(nNode.position.y - oNode.position.y) <= tolerance &&
                        abs(nNode.position.z - oNode.position.z) <= tolerance {
                        oNode.removeFromParentNode()
//                        previousScene!.rootNode.childNodes.remove(at: 1)
                    }
                    else {
                        nNode.geometry?.materials.first?.diffuse.contents = UIColor.lightGray
                    }
                }
            }
        }
    }
}
    
