//
//  CustomARAnchor.swift
//  accessibilita_cortile_elefante
//
//  Created by Giacomo Papaluca on 14/09/21.
//

import ARKit
import RealityKit

class CustomARAnchor: ARAnchor {
    
    var modelScalex: Float
    var modelScaley: Float
    var modelScalez: Float
    
    /*override init(name: String, transform: simd_float4x4) {
        self.modelTransform = Transform()
        super.init(name: name, transform: transform)
    }*/
    

    init(name: String, transform: float4x4, modelScale: SIMD3<Float>) {
        self.modelScalex = modelScale.x
        self.modelScaley = modelScale.y
        self.modelScalez = modelScale.z
        super.init(name: name, transform: transform)
    }


    required init(anchor: ARAnchor) {
        let other = anchor as! CustomARAnchor
        self.modelScalex = other.modelScalex
        self.modelScaley = other.modelScaley
        self.modelScalez = other.modelScalez
        super.init(anchor: other)
    }

    override class var supportsSecureCoding: Bool {
        return true
    }


    required init?(coder aDecoder: NSCoder) {
        if let modelScalex = aDecoder.decodeObject(forKey: "modelScalex") as? Float, let modelScaley = aDecoder.decodeObject(forKey: "modelScaley") as? Float, let modelScalez = aDecoder.decodeObject(forKey: "modelScalez") as? Float {
            self.modelScalex = modelScalex
            self.modelScaley = modelScaley
            self.modelScalez = modelScalez
        } else {
            return nil
        }
        super.init(coder: aDecoder)
    }



    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(modelScalex, forKey: "modelScalex")
        aCoder.encode(modelScaley, forKey: "modelScaley")
        aCoder.encode(modelScalez, forKey: "modelScalez")
    }
    
}
