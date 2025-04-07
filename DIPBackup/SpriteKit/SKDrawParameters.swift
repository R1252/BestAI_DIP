//
//  SKDrawParameters.swift
//  DIP
//
//  Created by Ray Septian Togi on 2024/10/11.
//

import UIKit
import SpriteKit

let floorPlanBackgroundColor = UIColor.white
let scalingFactor: CGFloat = 200

let hideSurfaceWidth: CGFloat = 24.0
let hideSurfaceZPosition: CGFloat = 1

let windowWidth: CGFloat = 8.0
let windowZPosition: CGFloat = 10

let doorArcWidth: CGFloat = 8.0
let doorZPosition: CGFloat = 20
let doorArcZPosition: CGFloat = 21

let objectOutlineWidth: CGFloat = 8.0
let objectZPosition: CGFloat = 30
let objectOutlineZPosition: CGFloat = 31

// Colors
//let floorPlanSurfaceColor = UIColor(named: "AccentColor")!
let floorPlanSurfaceColor = UIColor.black

// Line widths
let surfaceWidth: CGFloat = 22.0

// Rotation Angle 
var SKFPAngle: CGFloat = 0.0
var SKFPFrameSize = CGSizeZero

var textSetting = [
    NSAttributedString.Key.font : "Helvetica Bold" ,
    NSAttributedString.Key.foregroundColor : UIColor.black ,
    NSAttributedString.Key.strokeWidth : 24
] as [NSAttributedString.Key : Any]

