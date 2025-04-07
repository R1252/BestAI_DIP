//
//  CustomViewController.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/2/21.
//
import ARKit
import UIKit
import RealityKit
import RoomPlan
import SwiftUI

class CustomViewController: UIViewController, ARSessionDelegate {
    // RoomView variables
    let cameraNode = SCNNode()
    var csvData = CSVData()

    // ARCoaching variables
    let coachingOverlay = ARCoachingOverlayView()
    
    // Machine Learning variables
    /// Concurrent queue to be used for model predictions
    let predictionQueue = DispatchQueue(label: "predictionQueue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .inherit,
                                        target: nil)
    
    /// Layer used to host detectionOverlay layer
    var rootLayer: CALayer!
    /// The detection overlay layer used to render bounding boxes
    var detectionOverlay: CALayer!
//    var modelsForClassification: [ARMeshClassification: ModelEntity] = [:]
    var detectionBounds : [UIView] = []
    var frameCounter = 0
    var frameInterval = 5
    
    let ciContext = CIContext()
    var classes:[String] = []
    var yoloRequest: VNCoreMLRequest!
    
    /// Flag used to decide whether to draw bounding boxes for detected objects
    var showBoxes = true {
        didSet {
            if !showBoxes {
                removeBoxes()
            }
        }
    }
    
    /// Size of the camera image buffer (used for overlaying boxes)
    var bufferSize: CGSize! {
        didSet {
            if bufferSize != nil {
                if oldValue == nil {
                    setupLayers()
                } else if oldValue != bufferSize {
                    updateDetectionOverlaySize()
                }
            }
            
        }
    }
    /// last observed object
    var results = [VNRecognizedObjectObservation]()
    
    // Switches, Buttons, UIObjects
    /// Enable scanning
    @IBOutlet weak var scanSwitch : UISwitch!
    @IBOutlet var confidenceSlider : UISlider!
    @IBOutlet var iouSlider : UISlider!
    @IBOutlet weak var scanButton : UIButton!
    @IBOutlet weak var saveButton : UIButton!
    @IBOutlet weak var testButton : UIButton!
    @IBOutlet var cancelButton: UIBarButtonItem?
    @IBOutlet var panoramicPhotoButton : UIButton!
    @IBOutlet weak var statusLabel : UILabel!

    // widthMeasurement
    @IBOutlet weak var widthPicker : UIPickerView!
    @IBOutlet weak var widthSelectButton : UIButton!
    let pickerHandler = PickerHandler()
    
    var userInputText : String!
    var customCaptureView: CustomCaptureView!
    var thresholdProvider = ThresholdProvider()
    var destinationFolderURL : URL?
    var boxView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Custom Capture View
        resetVariables()
        customCaptureView = CustomCaptureView(frame: view.bounds)
        rootLayer = customCaptureView.layer
        view.insertSubview(customCaptureView, at: 1)
        
        // Delegate ARSession to CustomViewController to get updates
        customCaptureView.captureSession.arSession.delegate = self
        setupRoomView()
        setupLayers()
        
        widthPicker.dataSource = pickerHandler
        widthPicker.delegate = pickerHandler
    
//        setupCoachingOverlay()
//        printSubviewHierarchy()
        
        // setup defect detecting model
        guard let model = try? trainedmodel().model,
              let classes = model.modelDescription.classLabels as? [String],
              let vnModel = try? VNCoreMLModel(for: model) else {
            fatalError()
        }
        self.classes = classes
        vnModel.featureProvider = ThresholdProvider()
        
        yoloRequest = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
            self?.detection(request: request, error: error)
        }
        // see https://developer.apple.com/documentation/vision/vnimagecropandscaleoption for more information
        yoloRequest.imageCropAndScaleOption = .centerCrop
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view.addGestureRecognizer(tapGesture)
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTapGesture)
        tapGesture.require(toFail: doubleTapGesture)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        customCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        customCaptureView.captureSession.stop()
    }
    
    func setupRoomView(){
        roomView = SCNView()
        roomView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(roomView, at: 2)
        
        NSLayoutConstraint.activate([
            // Set width and height to 1/4 of the parent view
            roomView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9/*0.5*/),
            roomView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.9/*0.5*/),
            
            // Center the SCNView horizontally
            roomView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            roomView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: view.frame.height/6/*/4*/)
        ])
        
        let scene = SCNScene()
        roomView.scene = scene
        roomView.usesReverseZ = false
        roomView.backgroundColor = .clear
        
        //add camera
        let roomCamera = SCNCamera()
        cameraNode.camera = roomCamera
        roomView.scene?.rootNode.addChildNode(cameraNode)
        
        personNode.geometry = SCNSphere(radius: 0.2)
        personNode.geometry?.materials = [SCNMaterial()]
        personNode.geometry?.firstMaterial?.diffuse.contents = UIColor.red.withAlphaComponent(0.2)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? OnboardingViewController {
            if customCaptureView.savedRooms.count != 0 {
                nextViewController.loadViewIfNeeded()
                nextViewController.scanCollectionView.reloadData()
            }
        }
    }
    
//    func toggleButton(){
//        if customCaptureView.isScanning! {
//            scanButton.titleLabel?.text = "掃描結束"
//            saveButton.isEnabled = false
//            saveButton.backgroundColor = UIColor.lightGray
//            saveButton.titleLabel?.textColor = UIColor.white
//        }
//        else {
//            scanButton.titleLabel?.text = "繼續掃描"
//            saveButton.isEnabled = true
//            saveButton.backgroundColor = UIColor(named: "SecondaryUIColor")
//            saveButton.titleLabel?.textColor = UIColor(named: "ButtonColor")
//        }
//    }
    @IBAction func widthSelectButtonPressed(_ sender: UIButton) {
        let selectedValue = pickerHandler.selectedValue
        csvData.defect_width?.append(selectedValue)
        print("Debug - selected defect_width: \(selectedValue)")
        widthPicker.isHidden.toggle()
        widthSelectButton.isHidden.toggle()
    }
    
    @IBAction func panoramicButtonPressed(_ sender: UIButton){
        // add offset to prevent extreme edges
        let xOffset = view.frame.width * 0.02
        let yOffset = view.frame.height * 0.02
        let box = CGRect(x: xOffset/2, y: yOffset/2, width: view.frame.width - xOffset, height: view.frame.height - yOffset)
        print("Debug, box ",box)
        createAnchor(box: box, type: "panoramic")
    }
    
    // toggle scan
    @IBAction func scanButtonPressed(_ sender: UIButton){
//        toggleButton() 
        if customCaptureView.isScanning! {
            testButton.isHidden = false
            scanButton.isHidden = true
            customCaptureView?.captureSession.stop(pauseARSession: false)
        }
        else {
//            testButtonPressed(testButton)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton){
        if customCaptureView.savedRooms.count != 0 && customCaptureView.isScanning == false {
            // create folder
            destinationFolderURL = try! createFolder(newFolderName: userInputText)
            
            let doorsCount = customCaptureView.savedStructure!.doors.count
            let roomTemp = RoomScanned(folderName: userInputText,
                                       defectAnchors: customCaptureView.defectAnchors,
                                       camAnchors: customCaptureView.camAnchors,
                                       csvData: csvData,
                                       doorsCount: doorsCount)
            roomScanned.insert(roomTemp, at: roomScanned.count - 1)
            UserDefaults.standard.roomScannedList = roomScanned
            
            exportSCNUSDZ(roomTemp: roomTemp)
            exportUSDZ()
            exportFloorPlan()
            csvData.exportCSV(destinationFolderURL: destinationFolderURL!, savedImages: savedImages)
            saveImage(images: savedImages)
            
            performSegue(withIdentifier: "SegueID_4", sender: nil)
        }
    }
    
    // Short-term solution, may not be the efficient
    func exportSCNUSDZ(roomTemp: RoomScanned){
        let modelViewController = ModelViewController()
        modelViewController.sceneView = SCNView()
        modelViewController.sceneView.scene = SCNScene()
        modelViewController.selectedRoom = roomTemp
        modelViewController.getRoomProperties()
//        var labelledImages = [UIImage]()
//        for cImage in savedImages {
//            labelledImages.append(cImage.image)
//        }
//        modelViewController.images = labelledImages
        modelViewController.generateScene(model: customCaptureView.savedStructure!)
        modelViewController.destinationFolderURL = destinationFolderURL
        modelViewController.exportSCNUSDZ()
    }
    
    // Relocalize button
    @IBAction func testButtonPressed(_ sender: UIButton) {
        if customCaptureView.isScanning == false  {
            testButton.isHidden = true
            scanButton.isHidden = false
//            customCaptureView.savedRooms = finalResults
            customCaptureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        }
    }
    
//    @IBAction func getWidthButtonPressed(_ sender: UIButton){
//        let point = CGPoint(x: customCaptureView.frame.midX,y: customCaptureView.frame.midY)
//        let sphere = MeshResource.generateSphere(radius: 0.005)
//        let sphereMaterial = SimpleMaterial(color: .red, isMetallic: false)
//        let sphereEntity = ModelEntity(mesh: sphere, materials: [sphereMaterial])
//        var anchor_p1 : AnchorEntity?
//        
//        print("Debug - p1Position", p1Position)
//        
//        if p1Position == nil {
//            guard let p1 = customCaptureView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first else {
//                print("Debug - first point not detected")
//                return
//            }
//            anchor_p1 = AnchorEntity(raycastResult: p1)
//            anchor_p1!.addChild(sphereEntity)
//            p1Position = p1.worldTransform.position
//            customCaptureView.scene.addAnchor(anchor_p1!)
//        }
//        else {
//            let p2 = customCaptureView.raycast(from: point, allowing: .estimatedPlane, alignment: .any).first
//            let anchor_p2 = AnchorEntity(raycastResult: p2!)
//            anchor_p2.addChild(sphereEntity)
//            customCaptureView.scene.addAnchor(anchor_p2)
//            
//            let defectWidth = getDistance(p1Position!, p2!.worldTransform.position)
//            
//            print("Debug - defectWidth is ", defectWidth)
//            
//            //reset variables
//            anchor_p1?.removeFromParent()
//            anchor_p1?.children.removeAll()
//            p1Position = nil
//            anchor_p2.anchor!.removeFromParent()
//            anchor_p2.children.removeAll()
//            
//            csvData.defect_width?.append(defectWidth)
//            getWidthButton.isHidden.toggle()
//            defectScope.isHidden.toggle()
//        }
//    }
    
    @IBAction func cancelScanning(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
        customCaptureView.captureSession.stop(pauseARSession: true)
    }
    
    func resetVariables(){
        savedImages = []
        csvData = CSVData()
    }
    
    func printSubviewHierarchy() {
        for (index, subview) in self.view.subviews.enumerated() {
            print("Subview \(index): \(subview)")
        }
    }
}



