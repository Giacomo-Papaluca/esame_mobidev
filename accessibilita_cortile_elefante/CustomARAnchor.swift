//
//  CustomARAnchor.swift
//  accessibilita_cortile_elefante
//
//  Created by Giacomo Papaluca on 14/09/21.
//

import ARKit
import RealityKit

class CustomARAnchor: ARAnchor {
    
    var modelScale: String
    

    init(name: String, transform: float4x4, modelScale: SIMD3<Float>) {
        self.modelScale = modelScale.description
        super.init(name: name, transform: transform)
    }


    required init(anchor: ARAnchor) {
        let other = anchor as! CustomARAnchor
        self.modelScale = other.modelScale
        super.init(anchor: other)
    }

    override class var supportsSecureCoding: Bool {
        return true
    }


    required init?(coder aDecoder: NSCoder) {
        if let modelScale = aDecoder.decodeObject(forKey: "modelScale") as? String{
            self.modelScale = modelScale
        } else {
            return nil
        }
        super.init(coder: aDecoder)
    }



    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(modelScale, forKey: "modelScale")
    }
    
}
