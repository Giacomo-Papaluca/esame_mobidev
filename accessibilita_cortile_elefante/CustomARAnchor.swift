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
    var modelRotation: String
    var modelPosition: String
    

    init(name: String, transform: float4x4, modelScale: SIMD3<Float>) {
        self.modelScale = modelScale.description
        self.modelRotation = ""
        self.modelPosition = ""
        super.init(name: name, transform: transform)
    }


    required init(anchor: ARAnchor) {
        let other = anchor as! CustomARAnchor
        self.modelScale = other.modelScale
        self.modelRotation = other.modelRotation
        self.modelPosition = other.modelPosition
        super.init(anchor: other)
    }

    override class var supportsSecureCoding: Bool {
        return true
    }


    required init?(coder aDecoder: NSCoder) {
        if let modelScale = aDecoder.decodeObject(forKey: "modelScale") as? String, let modelRotation = aDecoder.decodeObject(forKey: "modelRotation") as? String, let modelPosition = aDecoder.decodeObject(forKey: "modelPosition") as? String {
            self.modelScale = modelScale
            self.modelRotation = modelRotation
            self.modelPosition = modelPosition
        } else {
            return nil
        }
        super.init(coder: aDecoder)
    }



    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(modelScale, forKey: "modelScale")
        aCoder.encode(modelRotation, forKey: "modelRotation")
        aCoder.encode(modelPosition, forKey: "modelPosition")
    }
    
}
