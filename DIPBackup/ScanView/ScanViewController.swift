//
//  ScanViewController.swift
//  DIP
//
//  Created by Ray Septian Togi on 2025/3/24.
//

import ARKit
import UIKit
import RealityKit
import RoomPlan
import SwiftUI

class ScanViewController: UIViewController, ARSessionDelegate {
    var camDist : Float =  0.0
    var camAngle : Float = 0.0
    var frameCounter = 0
    var optimalDistance : Float = 0.0
    var deviceHeightWidthRatio : Float = 0.0
    
    // RoomView variables
    let cameraNode = SCNNode()
    var csvData = CSVData()

    // ARCoaching variables
    let coachingOverlay = ARCoachingOverlayView()
    
    // Switches, Buttons, UIObjects
    /// Enable scanning
    @IBOutlet weak var stopScanButton : UIButton!
    @IBOutlet weak var saveButton : UIButton!
    @IBOutlet var cancelButton: UIBarButtonItem?
    @IBOutlet var panoramicPhotoButton : UIButton!
    @IBOutlet weak var statusLabel : UILabel!
    @IBOutlet weak var measurementLabel : UILabel!
    
    var userInputText : String!
    var scanView : ScanView!
    var destinationFolderURL : URL?
    var boxView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // scanView
        resetVariables()
        scanView = ScanView(frame: view.bounds)
        view.insertSubview(scanView, at: 1)
        
        // Delegate ARSession to CustomViewController to get updates
        scanView.captureSession.arSession.delegate = self
        setupRoomView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        scanView.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scanView.captureSession.stop()
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
        
        deviceHeightWidthRatio = Float(view.frame.height/view.frame.width)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nextViewController = segue.destination as? OnboardingViewController {
            if scanView.savedRooms.count != 0 {
                nextViewController.loadViewIfNeeded()
                nextViewController.scanCollectionView.reloadData()
            }
        }
    }
    
    @IBAction func panoramicButtonPressed(_ sender: UIButton) {
        let tolerance : Float = 0.2
        if camAngle > -10 && camAngle < 10 && camDist >= optimalDistance - tolerance && camDist <= optimalDistance + tolerance {
            // add offset to prevent extreme edges
            let xOffset = view.frame.width * 0.02
            let yOffset = view.frame.height * 0.02
            let box = CGRect(x: xOffset/2, y: yOffset/2, width: view.frame.width - xOffset, height: view.frame.height - yOffset)
            print("Debug, box ",box)
            createAnchor(box: box, type: "panoramic")
        } else {
            statusLabel.text = "Too Far / Too Close"
//            print("Debug - Too far or Too slanted")
        }
    }
    
    // toggle scan
    @IBAction func stopScanButtonPressed(_ sender: UIButton){
        if scanView.isScanning! {
            scanView?.captureSession.stop(pauseARSession: false)
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton){
        if scanView.isScanning == false {
            // create folder
            destinationFolderURL = try! createFolder(newFolderName: userInputText)
            
            let doorsCount = scanView.savedStructure!.doors.count
            let roomTemp = RoomScanned(folderName: userInputText,
                                       defectAnchors: scanView.defectAnchors,
                                       camAnchors: scanView.camAnchors,
                                       csvData: csvData,
                                       doorsCount: doorsCount)
            roomScanned.insert(roomTemp, at: roomScanned.count - 1)
            UserDefaults.standard.roomScannedList = roomScanned
            
            exportSCNUSDZ(roomTemp: roomTemp)
            exportUSDZ()
            exportFloorPlan()
            csvData.exportCSV(destinationFolderURL: destinationFolderURL!, savedImages: savedImages)
            saveImage(images: savedImages)
            
            performSegue(withIdentifier: "SegueID_6", sender: nil)
        }
    }
    
    // Short-term solution, may not be the efficient
    func exportSCNUSDZ(roomTemp: RoomScanned){
        let modelViewController = ModelViewController()
        modelViewController.sceneView = SCNView()
        modelViewController.sceneView.scene = SCNScene()
        modelViewController.generateScene(model: scanView.savedStructure!)
        modelViewController.destinationFolderURL = destinationFolderURL
        modelViewController.selectedRoom = roomTemp
        modelViewController.exportSCNUSDZ()
    }
    
    
    @IBAction func cancelScanning(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
        scanView.captureSession.stop(pauseARSession: true)
    }
    
    func resetVariables(){
        savedImages = []
        csvData = CSVData()
    }
}




