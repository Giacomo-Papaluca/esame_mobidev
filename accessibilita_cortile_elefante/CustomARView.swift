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
        if self.existingWorldMapURL != nil {
            showAlert(title: "Found world map!", message: "Found existing world map. If you didn't mean to load an existing map, be sure not to have a file named WorldMap in the root directory of the project.")
            loadExperience()
        }
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
    
    var existingWorldMapURL: URL? = Bundle.main.url(forResource: "WorldMap", withExtension: "")
    
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
        showAlert(title: "MAP SAVED!", message: "AR World Map successfully saved")
    }
    
    @IBAction func SalvaDidTap(_ sender: Any) {
        saveExperience()
    }
    
    func loadExperience() {
                
        /// - Tag: ReadWorldMap
        let mapData = try! Data(contentsOf: self.existingWorldMapURL!)
              
        let worldMap = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
            
        let configuration = self.defaultConfiguration
        configuration.initialWorldMap = worldMap
        self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        for anchor in worldMap!.anchors {
            addAnchorEntityToScene(anchor: anchor)
        }
            
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
            let biplaneModel = controlledLoadModelAsync(named: "toy_biplane")
            
            addModel(biplaneModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "arrow":
            let arrowModel = controlledLoadModelAsync(named: "arrow")
                        
            addModel(arrowModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "greenSquare":
            
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            let planeMaterial = SimpleMaterial(color: .green, roughness: MaterialScalarParameter(floatLiteral: 1), isMetallic: false)
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                        
            addModel(planeModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "redSquare":
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            let planeMaterial = SimpleMaterial(color: .red, roughness: MaterialScalarParameter(floatLiteral: 1), isMetallic: false)
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                        
            addModel(planeModel, to: anchorEntity, mappedWith: arAnchor)
            
            break
        case "dangerLine":
            let dangerModel = controlledLoadModelAsync(named: "dangerLine")
                        
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
    
    // MARK: - Restoring ARContent from existing map
    
    fileprivate func adjustModelEntity(_ modelEntity: ModelEntity, _ anchor: CustomARAnchor) {
        modelEntity.transform.scale = stringToSIMD3(scale: anchor.modelScale)
        modelEntity.transform.translation = stringToSIMD3(scale: anchor.modelPosition)
        modelEntity.transform.rotation = modelRotationToSimd_quatf(rotation: anchor.modelRotation)
        self.anchorOgbjectMapping[anchor.identifier] = modelEntity
        installGestures(on: modelEntity)
    }
        
    func addAnchorEntityToScene(anchor: ARAnchor) {
        let anchorEntity = AnchorEntity(anchor: anchor)
        
        if let _ = anchor as? ARImageAnchor {
            print("image found")
            let gioconda = models.first(where: {$0.modelName == "gioconda"})!.modelEntity!
            anchorEntity.addChild(gioconda)
        }
        
        if let anchor = anchor as? CustomARAnchor {
            print("anchor: " + anchor.name! + "; scale: " + anchor.modelScale)
            switch anchor.name {
                case "biplane":
                    let toyBiplaneEntity = controlledLoadModelAsync(named: "toy_biplane")
                    adjustModelEntity(toyBiplaneEntity, anchor)
                    anchorEntity.addChild(toyBiplaneEntity)
                    break
                case "arrow":
                    let arrowEntity = controlledLoadModelAsync(named: "arrow")
                    adjustModelEntity(arrowEntity, anchor)
                    anchorEntity.addChild(arrowEntity)
                    break
                case "greenSquare":
                    let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
                let planeMaterial = SimpleMaterial(color: .green, roughness: MaterialScalarParameter(floatLiteral: 1), isMetallic: false)
                    let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                    adjustModelEntity(planeModel, anchor)
                    anchorEntity.addChild(planeModel)
                    break
                case "redSquare":
                    let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
                    let planeMaterial = SimpleMaterial(color: .red, roughness: MaterialScalarParameter(floatLiteral: 1), isMetallic: false)
                    let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
                    adjustModelEntity(planeModel, anchor)
                    anchorEntity.addChild(planeModel)
                    break
                case "dangerLine":
                    let dangerEntity = controlledLoadModelAsync(named: "dangerLine")
                    adjustModelEntity(dangerEntity, anchor)
                    anchorEntity.addChild(dangerEntity)
                    break
                default:
                    return
            }
        }
            
        self.arView.scene.anchors.append(anchorEntity)
    }
        
        // MARK: -Parsing custom anchor properties
            
        private func stringToSIMD3(scale str: String) -> SIMD3<Float>{
            let suffix = str.suffix(from: str.index(str.startIndex, offsetBy: 13))
            var values = suffix.split(separator: ",")
            values[2].removeLast()
            values[2].removeFirst()
            values[1].removeFirst()
            for test in values { print(test)}
            return SIMD3(Float(values[0])!, Float(values[1])!, Float(values[2])!)
        }
            
        private func modelRotationToSimd_quatf(rotation str: String) -> simd_quatf {
            var values = str.split(separator: ",")
            let simd1 = Float(values[1].suffix(from: values[1].index(values[1].startIndex, offsetBy: 20)))!
            values[2].removeFirst()
            values[3].removeFirst()
            values[3].removeLast()
            values[3].removeLast()
            let simd = SIMD3(simd1, Float(values[2])!, Float(values[3])!)
            let realVal = Float(values[0].suffix(from: values[0].index(values[0].startIndex, offsetBy: 17)))!
            return simd_quatf(real: realVal, imag: simd)
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

extension CustomARView {
    func controlledLoadModelAsync(named name: String) -> ModelEntity {
        if name == "toy_biplane" {
            guard let entity = self.models.first(where: {$0.modelName == name})!.modelEntity else {
                return try! ModelEntity.loadModel(named: name)
            }
            return entity
        }
        else {
            guard let entity = self.models.first(where: {$0.modelName == name})!.modelEntity?.clone(recursive: true) else {
                return try! ModelEntity.loadModel(named: name)
            }
            return entity
        }
    }
}
