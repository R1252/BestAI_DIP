//
//  SKFloorPlan.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/10/11.
//

import RoomPlan
import ARKit
import SpriteKit

class FloorPlanScene : SKScene {
    private let surfaces : [CapturedRoom.Surface]
    private let objects : [CapturedRoom.Object]
    private let sections : [CapturedRoom.Section]
    private var room : RoomScanned
    var objectNodes : [SKNode] = []
    var images: [UIImage] = []
    private var selectedNodes : [SKNode] = []
    private var selectedNode = SKNode()
    private var door_index = 0
    var selectedDoorNode = SKNode()
    private var emptyNode = SKNode()
    private var imageNode = SKSpriteNode()
    
    private var previousCameraScale = CGFloat()
    private var previousCameraPosition = CGPoint()
    private var previousNodePosition = CGPoint()
        
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    init(structure : CapturedStructure, room: RoomScanned, images: [UIImage]){
        self.surfaces = structure.doors + structure.walls + structure.openings + structure.windows
        self.objects = structure.objects
        self.sections = structure.sections
        self.images = images
        self.room = room
        
        let coords = room.anchorCoords
        
        // get angle
        guard let surface = surfaces.first else {
            print("Debug - surfaces not found")
            super.init()
            return
        }
        
        SKFPAngle = CGFloat(surface.transform.eulerAngles.y)
//        print("Debug SKFPAngle, ", SKFPAngle)
        super.init(size: .zero)
        //range from 0 to 1.0, default is 0.0 for x and y axis || 0.5 center
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.backgroundColor = .white
        
        emptyNode.name = "empty"
        selectedNode = emptyNode
        drawScene()
        drawAnchors(coords: coords)
        addCamera()
    }

    override func didMove(to view: SKView) {
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: #selector(tapGestureAction(_:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.addTarget(self, action: #selector(panGestureAction(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
            
        let pinchGestureRecognizer = UIPinchGestureRecognizer()
        pinchGestureRecognizer.addTarget(self, action: #selector(pinchGestureAction(_:)))
        view.addGestureRecognizer(pinchGestureRecognizer)
    }
    
    @objc private func tapGestureAction(_ sender: UIPanGestureRecognizer) {
        let tapLocation = sender.location(in: sender.view)
        print("Debug - before converting tap location", tapLocation)
        
        let tapLocationInScene = self.convertPoint(fromView: tapLocation)
        let nodes = self.nodes(at: tapLocationInScene).filter{$0.isUserInteractionEnabled == true}
        if nodes.isEmpty {
            imageNode.isHidden = true
            selectedNode = emptyNode
        }
        else {
            for node in nodes {
                guard let name = node.name else {
                    continue
                }
                if name == "anchorNode" {
                    selectedNode = node
                }
                else if name.hasPrefix("door"){
                    selectedDoorNode = node
                    let highlightAction = SKAction.sequence([
                        SKAction.scale(to: 1.2, duration: 0.2),
                        SKAction.wait(forDuration: 0.05),  // Time to remain highlighted
                        SKAction.scale(to: 1.0, duration: 0.2) // Revert back
                    ])
                    node.run(highlightAction)
                }
                else if name.hasPrefix("defectNode") {
                    let index = Int(name.filter{$0.isNumber})!
                    // Multiply index by 2 because there's labelled images
                    skImageView.image = images[2*index]
                }
            }
        }
        print("Debug - Nodes found at tap location:", nodes)
    }
    
    @objc private func panGestureAction(_ sender: UIPanGestureRecognizer) {
        guard let camera = self.camera else { return }
        let xScale = camera.xScale
        let yScale = camera.yScale
        
        // Get the translation from the gesture recognizer
        let panTranslation = sender.translation(in: self.view)

        // Calculate the adjusted translation using camera rotation (angle)
        // Upwards negative y, left positive x
//        let xTranslation = panTranslation.y * cos(SKFPAngle) - panTranslation.x * sin(SKFPAngle)
//        let yTranslation = panTranslation.y * sin(SKFPAngle) + panTranslation.x * cos(SKFPAngle)
        var xTranslation = panTranslation.x * cos(SKFPAngle) - panTranslation.y * sin(SKFPAngle)
        var yTranslation = -panTranslation.x * sin(SKFPAngle) - panTranslation.y * cos(SKFPAngle)
        
        if SKFPAngle < 0.0 {
            xTranslation = panTranslation.x * cos(SKFPAngle) + panTranslation.y * sin(SKFPAngle)
            yTranslation = panTranslation.x * sin(SKFPAngle) - panTranslation.y * cos(SKFPAngle)
        }
            
        if sender.state == .began {
            previousNodePosition = selectedNode.position
            previousCameraPosition = camera.position
            // Reset the translation to avoid jumps
            sender.setTranslation(.zero, in: self.view)
        }

        // Handle pan for selected node
        if selectedNode.name != "empty" {
            let newNodePosition = CGPoint(
                x: previousNodePosition.x + xTranslation * xScale,
                y: previousNodePosition.y + yTranslation * yScale
            )
            selectedNode.position = newNodePosition
        }
        // Handle pan for camera movement
        else {
            let newCameraPosition = CGPoint(
                x: previousCameraPosition.x + xTranslation * xScale,
                y: previousCameraPosition.y + yTranslation * yScale
            )
            camera.position = newCameraPosition
        }
    }

    
    @objc private func pinchGestureAction(_ sender: UIPinchGestureRecognizer) {
        guard let camera = self.camera else { return }
        if sender.state == .began {
            previousCameraScale = camera.xScale
        }
        camera.setScale(previousCameraScale * 1 / sender.scale)
    }
    
    private func drawScene() {
        for surface in surfaces {
            let surfaceNode = FloorPlanSurface(capturedSurface: surface, doorIndex: door_index, room: room)
            if surface.category == .door(isOpen: false) || surface.category == .door(isOpen: true){
                door_index += 1
            }
            addChild(surfaceNode)
        }

        for object in objects {
            let objectNode = FloorPlanObject(capturedObject: object)
            objectNodes.append(objectNode)
            addChild(objectNode)
        }
        
        for section in sections {
            if section.label != .unidentified {
                let sectionNode = FloorPlanSection(section: section)
                addChild(sectionNode)
            }
        }
    }
    
    private func drawAnchors(coords: [[CGPoint]]){
        for (index,coord) in coords.enumerated() {
            let anchorNode = SKNode()
            anchorNode.isUserInteractionEnabled = true
            anchorNode.name = "anchorNode"
            anchorNode.position = coord[1]
            let endX = -coord[0].x * scalingFactor
            let endY = coord[0].y * scalingFactor
            let endPoint = CGPoint(x:endX, y:endY)
            // endPoint = tip of arrow
            
            // (-2) because the last point is the point for defect
            for i in 1...coord.count-2 {
                let pointX = -coord[i].x * scalingFactor
                let pointY = coord[i].y * scalingFactor
                let point = CGPoint(x: pointX, y: pointY)
                
                let path = CGMutablePath()
                path.move(to: endPoint)
                path.addLine(to: point)
                
                let shapeNode = SKShapeNode(path: path)
                shapeNode.strokeColor = .red
                shapeNode.lineWidth = surfaceWidth/6 * 4
                shapeNode.lineCap = .square
                shapeNode.lineJoin = .miter
                
                anchorNode.addChild(shapeNode)
            }
            
            // add defect pictures
            let defectNode = SKShapeNode(circleOfRadius: 15.0)
            defectNode.fillColor = .red
            defectNode.name = "defectNode".appending(String(index))
            defectNode.isUserInteractionEnabled = true
            defectNode.position = CGPoint(x: -coord[4].x * scalingFactor,
                                          y: coord[4].y * scalingFactor)
            // default value is 0.0, 1.0 is above
            defectNode.zPosition = 1.0
            addChild(defectNode)
            // add text label
            let text = SKLabelNode(text: String(index + 1))
            text.zRotation += CGFloat(SKFPAngle)
            text.fontName = "Helvetica Bold"
            text.fontColor = .black
            text.fontSize = 24 * 2
            let constant : CGFloat = 0.08 * 4
            if abs(coord[1].x - endX/scalingFactor) > abs(coord[1].y - endY/scalingFactor) {
                // The arrow is more y-aligned than it is x-aligned
                text.position = CGPoint(x: (-coord[1].x - constant) * scalingFactor,
                                        y: (coord[1].y + constant) * scalingFactor)
            } else {
                text.position = CGPoint(x: (-coord[1].x - constant) * scalingFactor,
                                        y: (coord[1].y + constant) * scalingFactor)
            }
            addChild(text)
            addChild(anchorNode)
        }
    }
      
    private func addCamera() {
        let cameraNode = SKCameraNode()
        cameraNode.zRotation = CGFloat(SKFPAngle)
        cameraNode.setScale(cameraNode.xScale * 1.2)
        camera = cameraNode
        addChild(cameraNode)
    }
}
