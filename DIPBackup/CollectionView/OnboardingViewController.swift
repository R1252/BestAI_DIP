import UIKit
import SpriteKit
import RoomPlan
import SceneKit
import ModelIO
import QuickLook

class OnboardingViewController: UIViewController , QLPreviewControllerDataSource {
    var room: RoomScanned?
    var capturedStructure: CapturedStructure!
    var images : [UIImage] = []
    var urlCellList : [URL] = []
    var selectedFileURL = URL(string: "")
    var selectedRoomIndex : Int = 0
    var fullPath : URL?
    var mode : String?
    
    @IBOutlet weak var userInput :UITextField!
    @IBOutlet weak var startVisualInspectionButton : UIButton!
    @IBOutlet weak var startPhotographyButton : UIButton!
    @IBOutlet weak var cancelButton : UIButton!
    @IBOutlet weak var popUpView: UIView!
    @IBOutlet weak var blurView: UIView!
    
    @IBOutlet weak var previewContainerView: UIView!
    let previewController = QLPreviewController()
    @IBOutlet var skView : SKView!
    var floorPlanScene : FloorPlanScene?
    
    @IBOutlet weak var exportCellButton : UIButton!
    @IBOutlet weak var editCellButton : UIButton!
    @IBOutlet weak var deleteButton : UIButton!
    
    @IBOutlet var scanCollectionView: UICollectionView!
    @IBOutlet var galleryCollectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        blurView.bounds = self.view.bounds
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        blurView.addGestureRecognizer(tapGesture)
        
        popUpView.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width * 0.5, height: self.view.bounds.height * 0.5)
        popUpView.layer.cornerRadius = 10
        
        scanCollectionView.dataSource = self
        scanCollectionView.delegate = self
        
        galleryCollectionView.dataSource = self
        galleryCollectionView.delegate = self
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        scanCollectionView.collectionViewLayout = flowLayout
        
        let galleryFlowLayout = UICollectionViewFlowLayout()
        galleryFlowLayout.scrollDirection = .vertical
        galleryCollectionView.collectionViewLayout = galleryFlowLayout
    }
    
    override func viewDidAppear(_ animated: Bool) {
     
    }
    
    func addSKDoorStyler(){
        let doorStylerButton = UIButton(type: .system)
        doorStylerButton.setTitle("Door Styler", for: .normal)
        doorStylerButton.backgroundColor = UIColor.lightGray
        doorStylerButton.addTarget(self, action: #selector(doorStylerPressed(_:)), for: .touchUpInside)

        // Add button to the view
        skView.addSubview(doorStylerButton)
        // Set translatesAutoresizingMaskIntoConstraints to false for autolayout
        doorStylerButton.translatesAutoresizingMaskIntoConstraints = false

        // Setup button constraints
        NSLayoutConstraint.activate([
            doorStylerButton.bottomAnchor.constraint(equalTo: skView.bottomAnchor, constant: -50),
            doorStylerButton.trailingAnchor.constraint(equalTo: skView.trailingAnchor, constant: -10),
            doorStylerButton.widthAnchor.constraint(equalTo: skView.widthAnchor, multiplier: 0.1),
            doorStylerButton.heightAnchor.constraint(equalTo: skView.heightAnchor, multiplier: 0.1)
        ])
    }
    
    func addSKViewImageView(){
        // furniture button
        skImageView.backgroundColor = UIColor.lightGray

        // Add button to the view
        skView.addSubview(skImageView)
        // Set translatesAutoresizingMaskIntoConstraints to false for autolayout
        skImageView.translatesAutoresizingMaskIntoConstraints = false

        // Setup button constraints
        NSLayoutConstraint.activate([
            skImageView.topAnchor.constraint(equalTo: skView.topAnchor, constant: 10),
            skImageView.trailingAnchor.constraint(equalTo: skView.trailingAnchor, constant: -10),
            skImageView.widthAnchor.constraint(equalTo: skView.widthAnchor, multiplier: 0.2),
            skImageView.heightAnchor.constraint(equalTo: skView.heightAnchor, multiplier: 0.2)
        ])
    }
    
    func addSKViewFurnitureButton(){
        // furniture button
        let hideShowFurnitureButton = UIButton(type: .system)
        hideShowFurnitureButton.setTitle("H/S", for: .normal)
        hideShowFurnitureButton.backgroundColor = UIColor.lightGray
        hideShowFurnitureButton.addTarget(self, action: #selector(hideShowFurniturePressed(_:)), for: .touchUpInside)

        // Add button to the view
        skView.addSubview(hideShowFurnitureButton)
        // Set translatesAutoresizingMaskIntoConstraints to false for autolayout
        hideShowFurnitureButton.translatesAutoresizingMaskIntoConstraints = false

        // Setup button constraints
        NSLayoutConstraint.activate([
            hideShowFurnitureButton.bottomAnchor.constraint(equalTo: skView.bottomAnchor, constant: -10),
            hideShowFurnitureButton.trailingAnchor.constraint(equalTo: skView.trailingAnchor, constant: -10),
            hideShowFurnitureButton.widthAnchor.constraint(equalTo: skView.widthAnchor, multiplier: 0.1),
            hideShowFurnitureButton.heightAnchor.constraint(equalTo: skView.heightAnchor, multiplier: 0.1)
        ])
    }
    
    func setupQLView(){
        // Create the container view for QLPreviewController
        previewContainerView?.backgroundColor = UIColor.white
        previewContainerView?.layer.cornerRadius = 30
        previewContainerView?.translatesAutoresizingMaskIntoConstraints = false
        animateIn(previewContainerView)
        
        // Set constraints for the container view
        NSLayoutConstraint.activate([
            previewContainerView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewContainerView!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewContainerView!.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            previewContainerView!.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.75)
        ])
        
        // Embed the QLPreviewController within the container view
        previewController.dataSource = self
        previewController.refreshCurrentPreviewItem()
        previewController.view.translatesAutoresizingMaskIntoConstraints = false
       
        addChild(previewController)
        previewContainerView?.addSubview(previewController.view)
        previewController.didMove(toParent: self)
       
        // Set constraints for the QLPreviewController view
        NSLayoutConstraint.activate([
           previewController.view.topAnchor.constraint(equalTo: skView.topAnchor),
           previewController.view.bottomAnchor.constraint(equalTo: skView.bottomAnchor),
           previewController.view.leadingAnchor.constraint(equalTo: skView.leadingAnchor),
           previewController.view.widthAnchor.constraint(equalTo: skView.widthAnchor)
       ])
    }
    
    @objc func hideShowFurniturePressed(_ sender: UIButton) {
        for node in floorPlanScene!.objectNodes {
            node.isHidden.toggle()
        }
    }
    
    @objc func doorStylerPressed(_ sender: UIButton) {
        let node = floorPlanScene!.selectedDoorNode
        for child in node.children {
            // only door shapes are named
            guard child.name != nil else {
                continue
            }
            child.isHidden.toggle()
        }
        guard let name = node.name else {
            return
        }
        // change state from open/close -> sliding and vice versa
        room!.doors[name]?.toggle()
        roomScanned[selectedRoomIndex] = room!// Assign back to ensure the change reflects
        UserDefaults.standard.roomScannedList = roomScanned
    }
    
    @IBAction func startVisualInspectionButtonPressed(_ sender: UIButton) {
        mode = "VisualInspection"
        cancelButtonPressed(sender)
        startScan()
    }
    
    @IBAction func startPhotographyButtonPressed(_ sender: UIButton) {
        mode = "Photography"
        cancelButtonPressed(sender)
        startScan()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        animateOut(popUpView)
    }
     
    @objc func handleTapGesture(_ recognizer: UIPanGestureRecognizer){
        if self.view.hideKeyboard() == false{
            dismissPreview()
        }
    }
    
    func dismissPreview() {
        previewContainerView?.removeFromSuperview()
        animateOut(popUpView)
    }
    
    // animate views
    func animateIn(_ desiredView: UIView){
        let views : [UIView] = [blurView, desiredView]
        let backgroundView = self.view!
        
        for view in views {
            backgroundView.addSubview(view)
            // set view scaling to be 120%
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            view.alpha = 0
            
            view.center = backgroundView.center
            if view == popUpView {
                view.center.y = view.center.y * 0.75
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                view.alpha = 1.0
            })
        }
    }
    
    func animateOut(_ desiredView: UIView){
        let views : [UIView] = [blurView,desiredView]
        for view in views {
            UIView.animate(withDuration: 0.3, animations: {
                view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                view.alpha = 0
            }, completion: { _ in view.removeFromSuperview()}
            )
        }
    }
    
    func startScan() {
        self.performSegue(withIdentifier: "SegueID_2", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UINavigationController  {
            guard let finalDestination = destination.viewControllers.first as? CustomViewController else {
                return
            }
            if userInput.text == "" {
                userInput.text = "Untitled"
            }
            finalDestination.userInputText = userInput.text
//            finalDestination.mode = mode!
        }
        
        else if let destination = segue.destination as? ModelViewController {
            destination.destinationFolderURL = fullPath!
            destination.selectedRoom = room!
            destination.model = capturedStructure
            
            var modelViewControllerImages = [UIImage]()
            // take odd pictures as they are unlabelled pictures
            for (i,image) in images.enumerated() {
                if i % 2 == 0 {
                    modelViewControllerImages.append(image)
                }
            }
            destination.images = modelViewControllerImages
        }
        
        else if let destination = segue.destination as? ScanViewController {
            if userInput.text == "" {
                userInput.text = "Untitled"
            }
            destination.userInputText = userInput.text
        }
      }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return images.count + 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let url = selectedFileURL else {
            print("Debug - No file URL selected")
            return Bundle.main.url(forResource: "FurnitureAssets.scnassets/Chair_Stool", withExtension: "usdz")! as QLPreviewItem
        }
        return url as QLPreviewItem
    }
    
    func loadRoom(indexPath : IndexPath) {
        // load room
        room = roomScanned[indexPath.row]
        let folderName = room!.folderName
//        anchorCoords = room!.anchorCoords
        
        fullPath = documentsDirectory.appendingPathComponent(folderName)
        let capturedRoomURL = fullPath?.appendingPathComponent("RoomData.json")

        // load images and capturedRoom
        do {
            var urlList = try FileManager.default.contentsOfDirectory(at: fullPath!, includingPropertiesForKeys: nil)
            urlList.sort { $0.absoluteString < $1.absoluteString }
            
            // Filter for image files
            let imageFiles = urlList.filter{ $0.pathExtension == "jpg" || $0.pathExtension == "png"}
            images = imageFiles.compactMap{UIImage(contentsOfFile: $0.path)}
            
            // Filter for usdz
            let usdzFiles = urlList.filter{$0.pathExtension == "usdz"}
            selectedFileURL = usdzFiles.first
            
            // 2D Plan
            let plan_2d = urlList.filter{$0.pathExtension == "dxf"}.first
            
            // Clear previous cells
            urlCellList = []
            
            // Load into cells
            urlCellList.append(contentsOf: imageFiles)
            urlCellList.append(contentsOf: usdzFiles)
            urlCellList.append(plan_2d!)
            
            // load capturedRoom
            let roomData = try Data(contentsOf: capturedRoomURL!)
            capturedStructure = try JSONDecoder().decode(CapturedStructure.self, from: roomData)
            
            // create floorPlanScene
            SKFPFrameSize = skView.frame.size
            floorPlanScene = FloorPlanScene(structure: capturedStructure, room: room!, images: images)
            floorPlanScene?.size = skView.frame.size
            skView.presentScene(floorPlanScene)
        } catch {
            print("Error while listing files in documents directory: \(error)")
        }
        
        // debug for urlList
//        print("Debug - Files in documents directory: \(urlList)")
//        for url in urlList {
//            print("debug", url.lastPathComponent)
//        }
        
        //setup
        addSKViewFurnitureButton()
        addSKViewImageView()
        addSKDoorStyler()
        setupQLView()
    }
    
    @IBAction func editCell(_ sender: UIButton) {
        dismissPreview()
        performSegue(withIdentifier: "SegueID_3", sender: nil)
    }
    
    @IBAction func exportCell(_ sender: UIButton) {
        let activityVC = UIActivityViewController(activityItems: [fullPath!], applicationActivities: nil)
        activityVC.modalPresentationStyle = .popover
        
        present(activityVC, animated: true, completion: nil)
        if let popOver = activityVC.popoverPresentationController {
            popOver.sourceView = self.exportCellButton
        }
    }
    
    @IBAction func deleteCell(_ sender: UIButton) {
        dismissPreview()
        roomScanned.remove(at: selectedRoomIndex)
        // Update UserDefaults
        UserDefaults.standard.roomScannedList = roomScanned
        scanCollectionView.deleteItems(at: [IndexPath(row: selectedRoomIndex, section: 0)])
        clearFolder(fullPath!)
    }
}

extension OnboardingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var returnValue = 0
        
        if collectionView == scanCollectionView {
            returnValue = roomScanned.count
        }
        
        // plus 3 because 2 3d model .usdz, and another for 2D spriteKit
        if collectionView == galleryCollectionView {
            returnValue = images.count + 3
        }
        
        return returnValue
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == scanCollectionView {
            if indexPath.row == roomScanned.count - 1 {
                let cell = scanCollectionView.dequeueReusableCell(withReuseIdentifier: "NewRoomScannedCollectionViewCell", for: indexPath) as! NewRoomScannedCollectionViewCell
                return cell
            } 
            else {
                let cell = scanCollectionView.dequeueReusableCell(withReuseIdentifier: "RoomScannedCollectionViewCell", for: indexPath) as! RoomScannedCollectionViewCell
                cell.setup(with: roomScanned[indexPath.row])
                return cell
            }
        } 
        
        else if collectionView == galleryCollectionView {
            let cell = galleryCollectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCollectionViewCell", for: indexPath) as! GalleryCollectionViewCell
            if urlCellList.count >= indexPath.row {
                cell.setup(with: urlCellList[indexPath.row].lastPathComponent)
            }
            return cell
        }
        
        else {
            preconditionFailure("Debug - Unknown collection view!")
        }
    }
}

extension OnboardingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == scanCollectionView {
            return (CGSize(width: 150, height: collectionView.frame.height))
        }
        
        else if collectionView == galleryCollectionView {
            return (CGSize(width: collectionView.frame.width, height: collectionView.frame.height/12))
        }
        
        return CGSize()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 1, bottom: 0, right: 1)
    }
}

extension OnboardingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == scanCollectionView {
            if indexPath.row == roomScanned.count-1{
                animateIn(popUpView)
            }
            
            else {
                selectedRoomIndex = indexPath.row
                loadRoom(indexPath: indexPath)
                galleryCollectionView.reloadData()
            }
        }
        
        else if collectionView == galleryCollectionView {
            galleryCollectionView.reloadData()
            let path = urlCellList[indexPath.row].lastPathComponent
            if path.hasSuffix(".jpg") || path.hasSuffix(".usdz"){
                previewContainerView.bringSubviewToFront(previewController.view)
                selectedFileURL = urlCellList[indexPath.row]
            }
            else if path.hasSuffix(".dxf"){
                previewContainerView.bringSubviewToFront(skView)
                skView.scene?.camera?.position = CGPointZero
            }
            else {
                print("Debug - nothing")
            }
            previewController.refreshCurrentPreviewItem()
        }
    }
    
//    func printSubviewHierarchy() {
//        for (index, subview) in self.popUpView.subviews.enumerated() {
//            print("Subview \(index): \(subview)")
//        }
//    }
}


