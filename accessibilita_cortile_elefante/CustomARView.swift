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
        if self.worldMapData != nil {
            self.loadExperience()
        }
        createWorldMapsFolder()
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
    
    func loadExperience() {
            
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = self.worldMapData
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
            
        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }
        
    func saveExperience() {
        self.arView.session.getCurrentWorldMap { worldMap, _ in
            guard let map = worldMap else {
                print("Can't get current world map")
                return
            }
            
            guard let snapshotAnchor = SnapshotAnchor(capturing: self.arView)
                else { fatalError("Can't take snapshot") }
            map.anchors.append(snapshotAnchor)
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: URL(fileURLWithPath: self.worldMapFilePath), options: [.atomic])
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func SalvaDidTap(_ sender: Any) {
        saveExperience()
    }
    // MARK: - Placing AR Content

    @objc private func arViewDidTap(_ sender: UITapGestureRecognizer){
        guard let result = self.arView.raycast(from: sender.location(in: self.arView), allowing: .existingPlaneGeometry, alignment: .horizontal).first else {
            return
        }
        
        let arAnchor = ARAnchor(name: actualObject, transform: result.worldTransform)
        self.arView.session.add(anchor: arAnchor)
        let anchorEntity = AnchorEntity(anchor: arAnchor)
        
        switch actualObject {
        case "biplane":
            let biplaneModel = models[0].modelEntity!
            anchorEntity.addChild(biplaneModel)
            installGestures(on: biplaneModel)
            break
        case "greenSquare":
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            var planeMaterial = SimpleMaterial()
            planeMaterial.baseColor = MaterialColorParameter.color(.green.withAlphaComponent(0.7))
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
            anchorEntity.addChild(planeModel)
            break
        case "redSquare":
            let planeMesh = MeshResource.generatePlane(width: 0.3, depth: 0.3)
            var planeMaterial = SimpleMaterial()
            planeMaterial.baseColor = MaterialColorParameter.color(.red.withAlphaComponent(0.7))
            let planeModel = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
            anchorEntity.addChild(planeModel)
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
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if frame.worldMappingStatus == .extending || frame.worldMappingStatus == .mapped {
            salvaButton.isEnabled=true
        }
        else {
            salvaButton.isEnabled=false
        }
        statusLabel.text = """
        Mapping: \(frame.worldMappingStatus.description)
        """
    }
    

}

// MARK: -EXTENSIONS

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

extension CGImagePropertyOrientation {
    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}

extension ARWorldMap {
    var snapshotAnchor: SnapshotAnchor? {
        return anchors.compactMap { $0 as? SnapshotAnchor }.first
    }
}
