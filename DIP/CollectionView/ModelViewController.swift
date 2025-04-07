//
//  ModelViewController.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/6/20.
//
import SceneKit
import RoomPlan

class ModelViewController: UIViewController, UIGestureRecognizerDelegate {
    var sceneView: SCNView!
    var destinationFolderURL : URL?
    var model : CapturedStructure?
    var images : [UIImage] = []
    var nodes: [SCNNode] = []
    var originalHeights: [SCNNode: Float] = [:]
    var originalY: [SCNNode: Float] = [:]

    let cameraNode = SCNNode()
    let camera = SCNCamera()
//    var floors = SCNNode()
    var dimension = 3
    
    // variables to draw defect on the 3D Model
    var selectedRoom : RoomScanned?
//    var bounds_3d : [simd_float3] = []
    var defectTransform : [simd_float4x4] = []
//    var csvData = CSVData()
//    var lastValue = CGFloat(0)
//    var selectedFileURL = URL(string: "")
    
    @IBOutlet weak var saveButton : UIButton!
    @IBOutlet weak var toggleFurniture : UIButton!
    @IBOutlet weak var toggleDimensions : UIButton!
    @IBOutlet weak var rotateLeft : UIButton!
    @IBOutlet weak var rotateRight : UIButton!
    
//    var scenePan = UIPanGestureRecognizer()
//    var sceneRotate = UIRotationGestureRecognizer()
//    var scenePinch = UIPinchGestureRecognizer()
    
    var currentPinch = Float(0)
    var currentRotation = Float(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = SCNView(frame: self.view.bounds)
        sceneView.scene = SCNScene()
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(sceneView, at: 0)
        
        self.sceneView.allowsCameraControl = true
//        cameraNode.camera = camera
//        cameraNode.position = SCNVector3(0.5,5,0.5)
//        cameraNode.eulerAngles = SCNVector3(-Float.pi/6, -Float(SKFPAngle), 0.0)
//        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        setupSkyLights()
        let floor = SCNFloor()
        floor.reflectivity = 0.1
        floor.firstMaterial?.diffuse.contents = UIImage(named: "grid")
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(64, 64, 0)

        let floorNode = SCNNode()
        floorNode.geometry = floor
        floorNode.eulerAngles.y = -Float(SKFPAngle)
        floorNode.name = "immovable"
//        floorNode.position = SCNVector3(0, 0, 0)
        sceneView.scene?.rootNode.addChildNode(floorNode)
//        setupSceneGestures()

        guard let model = model else {
            print("Debug - no valid model can be generated.")
            return
        }
        getRoomProperties()
        generateScene(model: model)
    }
    
    func setupSkyLights(){
        if let skyImage = UIImage(named: "sky") { // Use a sky image
            sceneView.scene?.background.contents = skyImage
        }
        sceneView.scene?.fogDensityExponent = 2.0
        sceneView.scene?.fogColor = UIColor(white: 5/6, alpha: 1.0)
        sceneView.scene?.fogStartDistance = 20.0
        sceneView.scene?.fogEndDistance = 50.0

        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.1, alpha: 0.1)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        sceneView.scene?.rootNode.addChildNode(ambientLightNode)

        // Omni Light
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.color = UIColor(white: 0.2, alpha: 1.0)
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        sceneView.scene?.rootNode.addChildNode(omniLightNode)
        
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor(white: 1.0, alpha: 1.0)
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.eulerAngles = SCNVector3(-Float.pi / 3, -Float.pi / 4, 0)
        sceneView.scene?.rootNode.addChildNode(directionalLightNode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func getRoomProperties() {
        guard let room = selectedRoom else {
            print("Debug - no RoomScanned was given")
            return
        }
//        bounds_3d = room.bounds_3d
        
        if !room.defectProperties.isEmpty {
            let defectProperties = room.defectProperties
            for index in 0...defectProperties.count/4 - 1 {
                let transform = simd_float4x4(defectProperties[4*index],
                                              defectProperties[4*index+1],
                                              defectProperties[4*index+2],
                                              defectProperties[4*index+3])
                defectTransform.append(transform)
            }
        }
    }
    
//    func setupSceneGestures() {
//        scenePan = UIPanGestureRecognizer(target: self, action: #selector(handleScenePan(_:)))
////        sceneRotate = UIRotationGestureRecognizer(target: self, action: #selector(handleSceneRotate(_:)))
//        scenePinch = UIPinchGestureRecognizer(target: self, action: #selector(handleScenePinch(_:)))
//        scenePan.delegate = self
//        scenePinch.delegate = self
////        sceneRotate.delegate = self
//
//        sceneView.addGestureRecognizer(scenePan)
//        sceneView.addGestureRecognizer(scenePinch)
//        //        sceneView.addGestureRecognizer(sceneRotate)
//    }
    
//    func toggleSceneGestures(_ enable: Bool){
//        scenePan.isEnabled = enable
//        scenePinch.isEnabled = enable
////        sceneRotate.isEnabled = enable
//    }
    
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
//        clearFolder(destinationFolderURL!)
        exportSCNUSDZ()
        nodes = []
        self.performSegue(withIdentifier: "SegueID_5", sender: nil)
    }
    
//    @IBAction func rotateRightPressed(_ sender: UIButton) {
//        let dx = cameraNode.position.x - floors.position.x
//        let dz = cameraNode.position.z - floors.position.z
//        let angle = cameraNode.eulerAngles.y + Float.pi/2
//        let radius = sqrt(dx * dx + dz * dz)
//        cameraNode.position.x = radius * cos(angle)
//        cameraNode.position.z = radius * sin(angle)
//        cameraNode.eulerAngles.y += Float.pi / 2
//        print("debug - camera angle y", cameraNode.eulerAngles.y)
//    }
//    
//    @IBAction func rotateLeftPressed(_ sender: UIButton) {
//        let dx = cameraNode.position.x - floors.position.x
//        let dz = cameraNode.position.z - floors.position.z
//        let angle = cameraNode.eulerAngles.y - Float.pi/2
//        let radius = sqrt(dx * dx + dz * dz)
//        cameraNode.position.x = radius * cos(angle)
//        cameraNode.position.z = radius * sin(angle)
//        cameraNode.eulerAngles.y -= Float.pi / 2
//        print("debug - camera angle y", cameraNode.eulerAngles.y)
//    }
    
   
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if let nextViewController = segue.destination as? OnboardingViewController {
//            if model != nil {
//                let roomTemp = RoomScanned(title: userInputText, folderURL: destinationFolderURL! ,roomURL: destinationFolderURL!.appendingPathComponent("Room.usdz"))
//                
//                roomScanned.insert(roomTemp, at: roomScanned.count - 1)
//                UserDefaults.standard.roomScannedList = roomScanned
//                nextViewController.loadViewIfNeeded()
//                nextViewController.scanCollectionView.reloadData()
//            }
//        }
//    }
    
    @IBAction func toggleDimensionsPressed() {
        toggleHeights()
        // 2D to 3D
        if dimension == 2 {
            cameraNode.eulerAngles = SCNVector3(-Float.pi/6, Float.pi/6, 0)
            cameraNode.camera?.fieldOfView = 45.0
            toggleDimensions.setTitle("3D", for: .normal)
            dimension = 3
        }
        // 3D to 2D
        else {
            cameraNode.position = SCNVector3(0,10,0)
            cameraNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
            cameraNode.camera?.fieldOfView = 45.0
            toggleDimensions.setTitle("2D", for: .normal)
            dimension = 2
        }
    }
    
    @IBAction func toggleFurniturePressed() {
        sceneView.scene?.rootNode.childNodes.forEach {node in
            guard let nodeName = node.name else {
                return
            }
            // check for furniture nodes
            if nodeName.hasPrefix("f_"){
                if node.isHidden == true {
                    node.isHidden = false
                } else {
                    node.isHidden = true
                }
            }
        }
    }
    
//    @objc func handleSceneRotate(_ gesture: UIRotationGestureRecognizer) {
//        currentRotation = Float(gesture.rotation)
//
////        if abs(gesture.rotation) > 0.01 {
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = 0.1
//        if dimension == 3 {
//            cameraNode.eulerAngles.y += currentRotation * 0.1
//        }
//        SCNTransaction.commit()
//        //         normalize
//        if cameraNode.eulerAngles.y > Float.pi {
//            cameraNode.eulerAngles.y -= 2 * Float.pi
//        }
//        else if cameraNode.eulerAngles.y < -Float.pi {
//            cameraNode.a.y += 2 * Float.pi
//        }
//        else { return }
//
////        }
//
//        gesture.rotation = 0
//    }
    
//    @objc func handleScenePinch(_ gesture: UIPinchGestureRecognizer) {
//        let currentPosition = cameraNode.position
//        let currentAngle = cameraNode.eulerAngles.y * 180 / .pi
//        let tolerance: Float = 45.0
//        currentPinch = Float(1 - gesture.scale)
//        if dimension == 3 {
//            SCNTransaction.begin()
//            SCNTransaction.animationDuration = 0.2
//            cameraNode.eulerAngles.x = min(max(cameraNode.eulerAngles.x + currentPinch, -Float.pi/2), 0)
//            cameraNode.position.y = min(max(currentPosition.y - currentPinch * 5, 1.0),12.0)
//            
//            switch currentAngle {
//            case let angle where abs(angle - 0) <= tolerance || abs(angle - 360) <= tolerance:
//                // Camera facing forward (0° or 360°)
//                cameraNode.position.z += currentPinch * 2.0
//
//            case let angle where abs(angle - 90) <= tolerance || abs(angle + 270) <= tolerance:
//                // Camera facing right (90° or - 270)
//                cameraNode.position.x += currentPinch * 2.0
//
//            case let angle where abs(angle - 270) <= tolerance || abs(angle + 90) <= tolerance:
//                // Camera facing left (270° or -90°)
//                cameraNode.position.x -= currentPinch * 2.0
//
//            case let angle where abs(angle - 180) <= tolerance || abs(angle + 180) <= tolerance:
//                // Camera facing backward (180° or -180°)
//                cameraNode.position.z -= currentPinch * 2.0
//
//            default:
//                // If angle is not close to any of the cardinal angles, keep the current position
//                break
//            }
//        }
//        SCNTransaction.commit()
//        gesture.scale = 1.0
//    }
    
//    @objc func handleScenePan(_ gesture: UIPanGestureRecognizer) {
//        // Get the translation of the pan gesture
//        let translation = gesture.translation(in: gesture.view)
//        let currentPosition = cameraNode.position
//        
//        // Convert the camera's y-angle from radians to degrees, ensuring it stays between 0° and 360°
//        let currentAngle = fmod(cameraNode.eulerAngles.y * 180 / .pi, 360)
//        let tolerance: Float = 45.0  // Tolerance around major angles
//        
//        // Adjust translation factors (scaled)
//        let translatedX = Float(translation.x * 0.03)
//        let translatedZ = Float(translation.y * 0.03)
//
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = 0.5
//        
////        print("Debug - current angle:", currentAngle)
//        // Determine camera movement based on the current angle (with tolerance)
//        switch currentAngle {
//        case let angle where abs(angle - 0) <= tolerance || abs(angle - 360) <= tolerance:
//            // Camera facing forward (0° or 360°)
//            cameraNode.position.x = currentPosition.x - translatedX
//            cameraNode.position.z = currentPosition.z - translatedZ
//
//        case let angle where abs(angle - 90) <= tolerance || abs(angle + 270) <= tolerance:
//            // Camera facing right (90° or - 270)
//            cameraNode.position.x = currentPosition.x - translatedZ
//            cameraNode.position.z = currentPosition.z + translatedX
//
//        case let angle where abs(angle - 270) <= tolerance || abs(angle + 90) <= tolerance:
//            // Camera facing left (270° or -90°)
//            cameraNode.position.x = currentPosition.x + translatedZ
//            cameraNode.position.z = currentPosition.z - translatedX
//
//        case let angle where abs(angle - 180) <= tolerance || abs(angle + 180) <= tolerance:
//            // Camera facing backward (180° or -180°)
//            cameraNode.position.x = currentPosition.x + translatedX
//            cameraNode.position.z = currentPosition.z + translatedZ
//
//        default:
//            // If angle is not close to any of the cardinal angles, keep the current position
//            break
//        }
//        
//        SCNTransaction.commit()
//        // Reset the translation so the gesture doesn't accumulate values
//        gesture.setTranslation(CGPoint.zero, in: gesture.view)
//    }

    
    /// outdated code
//    @objc func handleScenePan(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: gesture.view)
//        let currentPosition = cameraNode.position
//        // limit from 0 to 360
//        let currentAngle = fmod(cameraNode.eulerAngles.y * 180 / .pi, 360)
//        // degrees
//        let tolerance : Float = 45.0
//        
//        // Compute the pan direction based on the current camera angle
//        let rotatedX = Float(translation.x * 0.03)
//        let rotatedZ = Float(translation.y * 0.03)
//        
//        SCNTransaction.begin()
//        SCNTransaction.animationDuration = 0.5
//        print ("debug - current Angle" ,currentAngle)
//        
//        if currentAngle >= 0 - tolerance && currentAngle <= 0 + tolerance ||
//            currentAngle >= 360 - tolerance && currentAngle <= 360 + tolerance
//        {
//            cameraNode.position.x = currentPosition.x - rotatedX
//            cameraNode.position.z = currentPosition.z - rotatedZ
//        }
//        
//        if currentAngle >= 90 - tolerance && currentAngle <= 90 + tolerance ||
//            currentAngle >= -270 - tolerance && currentAngle <= -270 + tolerance
//        {
//            cameraNode.position.x = currentPosition.x - rotatedZ
//            cameraNode.position.z = currentPosition.z + rotatedX
//        }
//        
//        if currentAngle >= -90 - tolerance && currentAngle <= -90 + tolerance ||
//            currentAngle >= 270 - tolerance && currentAngle <= 270 + tolerance
//        {
//            cameraNode.position.x = currentPosition.x + rotatedZ
//            cameraNode.position.z = currentPosition.z - rotatedX
//        }
//        
//        if currentAngle >= 180 - tolerance && currentAngle <= 180 + tolerance ||
//            currentAngle >= -180 - tolerance && currentAngle <= -180 + tolerance
//        {
//            cameraNode.position.x = currentPosition.x + rotatedX
//            cameraNode.position.z = currentPosition.z + rotatedZ
//        }
//    
//        SCNTransaction.commit()
//        // Reset the translation
//        gesture.setTranslation(CGPoint.zero, in: gesture.view)
//    }

    func exportSCNUSDZ() {
        guard let destinationFolderURL = destinationFolderURL else {
            print("Debug - Destination folder URL is nil.")
            return
        }
        let destinationURL = destinationFolderURL.appendingPathComponent("Room_Textured.usdz")
        sceneView.scene!.write(to: destinationURL, options: nil, delegate: nil, progressHandler: nil)
    }
}
