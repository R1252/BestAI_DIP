//
//  Global Variables.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/12/24.
//

/// Variables to store data || Be very careful when modifying ||

import Foundation
import SceneKit
import RoomPlan

let documentsDirectory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
var savedImages : [CustomImage] = []
var roomView : SCNView!
var roomFloor : CapturedRoom.Surface?
var roomScale : Float = 0.0
//let cameraNode = SCNNode()
let personNode = SCNNode()
var previousScene : SCNScene?

let skImageView = UIImageView()
