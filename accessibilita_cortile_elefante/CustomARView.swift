//
//  CustomARView.swift
//  accessibilita_cortile_elefante
//
//  Created by Giacomo Papaluca on 07/09/21.
//

import UIKit
import RealityKit
import ARKit

class CustomARView: UIViewController, ARSessionDelegate {

    @IBOutlet weak var arView: ARView!
    
    @IBOutlet weak var salvaButton: UIButton!
    
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.environmentTexturing = .automatic
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }
            return configuration
    }
    
    // MARK: - Init and setup
        
    func setup() {
        self.arView.session.run(defaultConfiguration)
        self.arView.session.delegate = self
        self.arView.debugOptions = [ .showFeaturePoints ]
        self.loadExperience()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - Persistence: Saving and Loading
    
    var mapSaveURL: URL = Bundle.main.url(forResource: "WorldMap", withExtension: "")!
        
    
    func loadExperience() {
            
        /// - Tag: ReadWorldMap
        let mapData = try! Data(contentsOf: mapSaveURL)
          
        let worldMap = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
        
   
    func addAnchorEntityToScene(anchor: ARAnchor) {
        let anchorEntity = AnchorEntity(anchor: anchor)
        switch anchor.name {
            case "biplane":
                let toyBiplaneEntity = try! ModelEntity.loadModel(named: "toy_biplane")
                anchorEntity.addChild(toyBiplaneEntity)
                self.arView.scene.anchors.append(anchorEntity)
                break
            case "greenSquare":
                let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
                var planeMaterial = UnlitMaterial()
                planeMaterial.baseColor = MaterialColorParameter.color(.green.withAlphaComponent(0.7))
                let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                anchorEntity.addChild(planeModel)
                self.arView.scene.anchors.append(anchorEntity)
                break
            case "redSquare":
                let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
                var planeMaterial = UnlitMaterial()
                planeMaterial.baseColor = MaterialColorParameter.color(.red.withAlphaComponent(0.7))
                let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                anchorEntity.addChild(planeModel)
                self.arView.scene.anchors.append(anchorEntity)
                break
            default:
                return
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("did add anchor: \(anchors.count) anchors in total")
            
        for anchor in anchors {
            addAnchorEntityToScene(anchor: anchor)
        }
    }
    

}
