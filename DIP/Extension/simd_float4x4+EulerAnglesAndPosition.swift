//
//  simd_float4x4+EulerAnglesAndPosition.swift
//  RoomPlan 2D
//
//  Created by Dennis van Oosten on 10/03/2023.
//

import SceneKit

// returns angle 

extension simd_float4x4 {
    var eulerAngles: simd_float3 {
        simd_float3(
            x: asin(-self[2][1]),
            y: atan2(self[2][0], self[2][2]),
            z: atan2(self[0][1], self[1][1])
//            x: atan2(self[1][2], self[2][2]),
//            y: asin(self[0][2]),
//            z: atan2(self[0][1], self[0][0])
        )
    }

    var position: simd_float3 {
           get {
               simd_float3(
                   x: self.columns.3.x,
                   y: self.columns.3.y,
                   z: self.columns.3.z
               )
           }
           set {
               // Set the position by modifying the 4th column
               self.columns.3.x = newValue.x
               self.columns.3.y = newValue.y
               self.columns.3.z = newValue.z
           }
       }
}

extension SCNMatrix4 {
    var eulerAngles: simd_float3 {
        simd_float3(
            x: asin(-self.m32),
            y: atan2(self.m31, self.m33),
            z: atan2(self.m12, self.m22)
        )
    }
    
    var position: simd_float3 {
           get {
               simd_float3(
                   x: self.m41,
                   y: self.m42,
                   z: self.m43
               )
           }
           set {
               // Set the position by modifying the 4th column
               self.m41 = newValue.x
               self.m42 = newValue.y
               self.m43 = newValue.z
           }
       }
}
