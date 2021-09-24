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

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var arView: ARView!
    
    @IBOutlet weak var salvaButton: UIButton!
    
    private var actualObject: String = ""
    
    private var anchorOgbjectMapping: [UUID:ModelEntity] = [:]
    private var removedAnchors: [UUID] = []
    
    private var models: [Model] = {
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try? filemanager.contentsOfDirectory(atPath: path) else {
            return []
        }
        
        var availableModels: [Model] = []
        for filename in files where
            filename.hasSuffix("usdz"){
            let modelName = filename.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            availableModels.append(model)
        }
        
        return availableModels
    } ()
    
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            configuration.environmentTexturing = .automatic
            return configuration
    }
    
    @IBOutlet var showMenuButton: UIButton!
        
    var menuItems: [UIAction] {
        return [
            UIAction(title: "biplane") {_ in
                self.actualObject = "biplane"
            },
            UIAction(title: "greenSquare") { _ in
                self.actualObject = "greenSquare"
            },
            UIAction(title: "redSquare") { _ in
                self.actualObject = "redSquare"
            },
            UIAction(title: "arrow") {_ in
                self.actualObject = "arrow"
            },
            UIAction(title: "dangerLine") {_ in
                self.actualObject = "dangerLine"
            }
        ]
    }
    

    var demoMenu: UIMenu {
        return UIMenu(title: "oggetti", image: nil, identifier: nil, options: [], children: menuItems)
    }

    func configureButtonMenu() {
        showMenuButton.menu = demoMenu
        showMenuButton.showsMenuAsPrimaryAction = true
    }
    
    // MARK: - Init and setup
        
    func setup() {
        self.arView.session.run(defaultConfiguration)
        self.arView.session.delegate = self
        self.arView.debugOptions = [ .showFeaturePoints ]
        self.arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(arViewDidTap(_:))) )
        createWorldMapsFolder()
        enableObjectRemoval()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.configureButtonMenu()
        // Do any additional setup after loading the view.
    }
    
    
    // MARK: - Persistence: Saving and Loading
        
    func createWorldMapsFolder() {

        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        if let documentDirectoryPath = documentDirectoryPath {
                
            let replayDirectoryPath = documentDirectoryPath.appending("/WorldMaps")
            let fileManager = FileManager.default

            if !fileManager.fileExists(atPath: replayDirectoryPath) {

                do {
                    try fileManager.createDirectory(atPath: replayDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print("Error creating Captures folder in documents dir: \(error)")
                }
            } else {
                print("WorldMaps folder already created. No need to create.")
            }
        }
    }
    
    var worldMapFilePath: String{

                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let documentsDirectory = paths[0] as String
                let filePath: String = "\(documentsDirectory)/WorldMaps/WorldMap"
                return filePath

    }
    
    var worldMapData: Data? {
            return try? Data(contentsOf: URL(fileURLWithPath: self.worldMapFilePath))
    }
    
        
    func saveExperience() {
        self.arView.session.getCurrentWorldMap { worldMap, _ in
            guard let map = worldMap else {
                self.showAlert(title: "Can't get worold map!", message: "Can't get current worold map.\n\nRetry later.")
                return
            }
            
            
            //saving realityKit models info in customARAnchors
            for couple in self.anchorOgbjectMapping {
                print(couple)
                let model = couple.value
                let anchor = map.anchors.first(where: {$0.identifier == couple.key}) as! CustomARAnchor
                anchor.modelScale = model.transform.scale.description
                anchor.modelRotation = model.transform.rotation.debugDescription
                anchor.modelPosition = model.transform.translation.description
            }
            //removing anchors associated with removed entities
            for id in self.removedAnchors {
                map.anchors.removeAll(where: {$0.identifier == id})
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: URL(fileURLWithPath: self.worldMapFilePath), options: [.atomic])
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
            for test in map.anchors {
                if let anchor = test as? CustomARAnchor {
                    let str = anchor.modelScale.description
                    print("anchor: " + anchor.name! + "; scale: \(str)")
                }
            }
        }
    }
    
    @IBAction func SalvaDidTap(_ sender: Any) {
        saveExperience()
    }
    // MARK: - Placing AR Content

    fileprivate func addModel(_ modelEnity: ModelEntity, to anchorEntity: AnchorEntity, mappedWith arAnchor: CustomARAnchor) {
        anchorEntity.addChild(modelEnity)
        installGestures(on: modelEnity)
        
        self.anchorOgbjectMapping[arAnchor.identifier] = modelEnity
    }
    
    @objc private func arViewDidTap(_ sender: UITapGestureRecognizer){
        guard let result = self.arView.raycast(from: sender.location(in: self.arView), allowing: .existingPlaneGeometry, alignment: .horizontal).first else {
            return
        }
        
        let arAnchor = CustomARAnchor(name: actualObject, transform: result.worldTransform)
        self.arView.session.add(anchor: arAnchor)
        let anchorEntity = AnchorEntity(anchor: arAnchor)
        
        switch actualObject {
        case "biplane":
            let biplaneModel = models.first(where: {$0.modelName == "toy_biplane"})!.modelEntity!
            
            addModel(biplaneModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "arrow":
            let arrowModel = models.first(where: {$0.modelName == "arrow"})!.modelEntity!.clone(recursive: true)
                        
            addModel(arrowModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "greenSquare":
            
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            var planeMaterial = SimpleMaterial()
            planeMaterial.baseColor = MaterialColorParameter.color(.green.withAlphaComponent(0.7))
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                        
            addModel(planeModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "redSquare":
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            var planeMaterial = SimpleMaterial()
            planeMaterial.baseColor = MaterialColorParameter.color(.red.withAlphaComponent(0.7))
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                        
            addModel(planeModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "dangerLine":
            let dangerModel = models.first(where: {$0.modelName == "dangerLine"})!.modelEntity!.clone(recursive: true)
                        
            addModel(dangerModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        default:
            return
        }
        
        self.arView.scene.addAnchor(anchorEntity)
    
    }
    
    func installGestures(on object:ModelEntity){
        object.generateCollisionShapes(recursive: true)
        arView.installGestures([.rotation, .scale, .translation], for: object)
    }
    
    func enableObjectRemoval(){
        self.arView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:))))
    }
    
    @objc func handleLongPress(recognizer: UILongPressGestureRecognizer){
        let location = recognizer.location(in: self.arView)
        
        if let entity = self.arView.entity(at: location) {
            if let anchorEntity = entity.anchor, let anchor = anchorEntity.anchor {
                if let id = anchor.anchorIdentifier, let _ = anchorOgbjectMapping[id] {
                    anchorOgbjectMapping.removeValue(forKey: id)
                    removedAnchors.append(id)
                    print("eliminato mapping con id \(id)")
                }
                anchorEntity.removeFromParent()
            }
        }
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.worldMappingStatus == .extending || frame.worldMappingStatus == .mapped {
            salvaButton.isEnabled=true
            salvaButton.isHidden=false
        }
        else {
            salvaButton.isEnabled=false
            salvaButton.isHidden=true
        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        """
    }
    

}

extension ARFrame.WorldMappingStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Not Available"
        case .limited:
            return "Limited"
        case .extending:
            return "Extending"
        case .mapped:
            return "Mapped"
        @unknown default:
            return "Unknown"
        }
    }
}

extension UIViewController {
    func showAlert(title: String,
                   message: String,
                   buttonTitle: String = "OK",
                   showCancel: Bool = false,
                   buttonHandler: ((UIAlertAction) -> Void)? = nil) {
        print(title + "\n" + message)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: buttonHandler))
        if showCancel {
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        }
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
