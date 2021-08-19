//
//  CustomARView.swift
//  ARPersistence-Realitykit
//
//  Created by hgp on 1/17/21.
//
import SwiftUI
import RealityKit
import ARKit

class CustomARView: ARView {
    
    var saveble: Bool = false
    var loadable: Bool = false
    
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
        self.session.run(defaultConfiguration)
        self.session.delegate = self
        self.setupGestures()
        self.debugOptions = [ .showFeaturePoints ]
        if self.worldMapData != nil {
            self.loadExperience()
        }
    }
    
    // MARK: - AR content
    var virtualObjectAnchor: ARAnchor?
    let virtualObjectAnchorName = "virtualObject"
    var virtualObject = AssetModel(name: "toy_biplane.usdz")
    
    
    // MARK: - AR session management
    var isRelocalizingMap = false
    
 
    // MARK: - Persistence: Saving and Loading
    let storedData = UserDefaults.standard
    let mapKey = "ar.worldmap"

    lazy var worldMapData: Data? = {
        storedData.data(forKey: mapKey)
    }()
    
    func resetTracking() {
        self.session.run(defaultConfiguration, options: [.resetTracking, .removeExistingAnchors])
        self.isRelocalizingMap = false
        self.virtualObjectAnchor = nil
    }
    
    /// Add the tap gesture recogniser
    func setupGestures() {
      let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
      self.addGestureRecognizer(tap)
    }

    // MARK: - Placing AR Content

    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        // Disable placing objects when the session is still relocalizing
        if isRelocalizingMap && virtualObjectAnchor == nil {
            return
        }
        // Hit test to find a place for a virtual object.
        guard let point = sender?.location(in: self),
              let hitTestResult = self.hitTest(
                point,
                types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane]
        ).first
        else { return }

        // Remove exisitng anchor and add new anchor
        if let existingAnchor = virtualObjectAnchor {
            self.session.remove(anchor: existingAnchor)
        }
        virtualObjectAnchor = ARAnchor(
            name: virtualObjectAnchorName,
            transform: hitTestResult.worldTransform
        )
        
        // Add ARAnchor into ARView.session, which can be persisted in WorldMap
        self.session.add(anchor: virtualObjectAnchor!)
    }
    
    //MARK: addAnchorEntityToScene
    
    func addAnchorEntityToScene(anchor: ARAnchor) {
        guard anchor.name == virtualObjectAnchorName else {
            return
        }
        // save the reference to the virtual object anchor when the anchor is added from relocalizing
        if virtualObjectAnchor == nil {
            virtualObjectAnchor = anchor
        }
        
        if let modelEntity = virtualObject.modelEntity {
            print("DEBUG: adding model to scene - \(virtualObject.name)")
            
            // Add modelEntity and anchorEntity into the scene for rendering
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.addChild(modelEntity)
            self.scene.addAnchor(anchorEntity)
        } else {
            print("DEBUG: Unable to load modelEntity for \(virtualObject.name)")
        }
    }
    
    // MARK: - Persistence: Saving and Loading
    
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
        self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        self.loadable = false
        isRelocalizingMap = true
        virtualObjectAnchor = nil
    }
    
    func saveExperience() {
        self.session.getCurrentWorldMap { worldMap, _ in
            guard let map = worldMap else {
                print("Can't get current world map")
                return
            }
            
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                self.storedData.set(data, forKey: self.mapKey)
                self.saveble = true
            } catch {
                fatalError("Can't save map: \(error.localizedDescription)")
            }
        }
    }
    
}

// MARK: session delegate extension

extension CustomARView: ARSessionDelegate {
    
    // MARK: - AR session delegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
    }
    
    // This is where we render virtual contents to scene.
    // We add an anchor in `handleTap` function, it will then call this function.
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("did add anchor: \(anchors.count) anchors in total")
        
        for anchor in anchors {
            addAnchorEntityToScene(anchor: anchor)
        }
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Enable Save button only when the mapping status is good and an object has been placed
        if frame.worldMappingStatus == .extending || frame.worldMappingStatus == .mapped {
            saveExperience()
        }
    }

    
}
