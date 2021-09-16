//
//  Model.swift
//  accessibilita_cortile_elefante
//
//  Created by Giacomo Papaluca on 15/09/21.
//

import RealityKit
import Combine

class Model {
    var modelName: String
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        let filename = modelName + ".usdz"
        
        self.cancellable = ModelEntity.loadModelAsync(named: filename)
            .sink(receiveCompletion: { loadCompletition in
                print("DEBUG: unable to load \(modelName)")
            }, receiveValue: { modelEntity in
                self.modelEntity = modelEntity
                print("DEBUG: successfully loaded \(modelName)")
            })
    }
    
}
