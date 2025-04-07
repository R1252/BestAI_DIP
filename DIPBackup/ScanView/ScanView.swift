//
//  ScanCaptureView.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//
import UIKit
import RealityKit
import RoomPlan
import ARKit

class ScanView: ARView, RoomCaptureSessionDelegate {
    var roomBuilder = RoomBuilder(options: [.beautifyObjects])
    var structureBuilder = StructureBuilder(options: [.beautifyObjects])
    var statusLabelText : String?
    var captureSession: RoomCaptureSession = RoomCaptureSession()
    
    var savedStructure : CapturedStructure?
    var savedRooms : [CapturedRoom] = []
    var surfaceInRoom : [CapturedRoom.Surface] = []
    var wallNodes : [SCNNode] = []
    var wallHeight : Float = 0
    
    var defectAnchors : [ARAnchor] = []
    var camAnchors : [ARAnchor] = []
    var anchorNumberForIdentification = 0
    
    var isScanning : Bool?
    
    required init(frame: CGRect){
        super.init(frame: frame)
        print("Debug - requiredInit")
        initSession()
    }
    
    @MainActor required dynamic init?(coder decoder: NSCoder){
        super.init(coder: decoder)
        print("Debug - Main Actor requiredInit")
        initSession()
    }
    
    func initSession(){
        self.cameraMode = .ar
        captureSession.delegate = self
        print("Debug - Session Init again")
    }
    
    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        
        print("Debug - sessionStartedAgain")
        self.session = captureSession.arSession
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.sceneReconstruction = .meshWithClassification
        arConfiguration.planeDetection = [.vertical,.horizontal]
        arConfiguration.environmentTexturing = .automatic
        
        isScanning = true
        statusLabelText = "Starting RoomCaptureSession!"
        self.captureSession.arSession.run(arConfiguration)
    }
    
    func captureSession(_ session: RoomCaptureSession, didUpdate: CapturedRoom) {
        DispatchQueue.main.async { [self] in
        Task {
            savedStructure = try await structureBuilder.capturedStructure(from: [didUpdate])
            }
            let wall = savedStructure?.walls.first
            wallHeight = wall?.dimensions.y ?? 0
            roomFloor = savedStructure?.floors.first
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        DispatchQueue.main.async { [self] in
            Task {
                var planes : [CapturedRoom.Surface] = []
                var wallOpenings : [CapturedRoom.Surface] = []
                
                planes = room.floors + room.walls // floors aren't drawn for some reason
                wallOpenings = room.windows + room.doors + room.openings
                
                for plane in planes {
                    drawPlanes(scene: roomView.scene!, surface: plane)
                }
                
                for wallOpening in wallOpenings {
                    drawSurface(scene: roomView.scene!, surface: wallOpening)
                    surfaceInRoom.append(wallOpening)
                }
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        DispatchQueue.main.async { [self] in
            Task {
                var updatedSurface : [CapturedRoom.Surface] = []
                updatedSurface = room.floors + room.walls + room.windows + room.doors + room.openings
                
                for surface in updatedSurface {
                    updatePlanes(scene: roomView.scene!, surface: surface)
                }
            }
        }
    }
    
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        var deletedSurface : [CapturedRoom.Surface] = []
        let childNodes = roomView.scene!.rootNode.childNodes
            
        DispatchQueue.main.async { [self] in
            Task {
                deletedSurface = room.floors + room.walls + room.windows + room.doors + room.openings
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
        Task {
            statusLabelText = "captureSession ended"
            isScanning = false
            previousScene = roomView.scene
        }
        session.stop(pauseARSession: false)
    }
    
    func cleanScene() {
        roomView.scene?.rootNode.childNodes.forEach { node in
            node.removeFromParentNode()
        }
        wallNodes.removeAll()
        surfaceInRoom.removeAll()
    }
}
    

