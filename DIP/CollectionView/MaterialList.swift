//
//  MaterialList.swift
//  簡單風水
//
//  Created by Ray Septian Togi on 2024/7/4.
//

import SceneKit

var wallMaterial: SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIColor(named: "Wall")
    material.isDoubleSided = true
    return material
}

var doorMaterial: SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIImage(named: "doorTexture")
    material.isDoubleSided = true
    return material
}

var floorMaterial : SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIImage(named: "floor")
    material.isDoubleSided = true
    return material
}

var windowMaterial : SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIColor(white: 1.0, alpha: 0.2)
    material.transparency = 0.5
    material.reflective.contents = UIColor.white
    material.reflective.intensity = 0.6
    material.roughness.contents = NSNumber(value: 0.1)
    material.clearCoat.contents = UIColor.white
    material.clearCoat.intensity = 0.5
    material.specular.contents = UIColor.white
    material.shininess = 0.8
    material.isDoubleSided = true
    return material
}

var openingMaterial: SCNMaterial {
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.clear
    material.isDoubleSided = true
    return material
}
