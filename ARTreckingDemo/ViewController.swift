//
//  ViewController.swift
//  ARTreckingDemo
//
//  Created by Arpit iOS Dev. on 11/07/24.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Gesture Recognizer
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        let touchLocation = gestureRecognize.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint)
        
        if let result = hitTestResults.first {
            let position = SCNVector3(result.worldTransform.columns.3.x,
                                      result.worldTransform.columns.3.y,
                                      result.worldTransform.columns.3.z)
            
            let node = createUniqueNode()
            node.position = position
            sceneView.scene.rootNode.addChildNode(node)
            
            let animation = CABasicAnimation(keyPath: "position")
            animation.fromValue = NSValue(scnVector3: SCNVector3(position.x, position.y - 0.1, position.z))
            animation.toValue = NSValue(scnVector3: position)
            animation.duration = 0.5
            node.addAnimation(animation, forKey: "position")
        }
    }
    
    // MARK: - Helper Methods
    
    func createUniqueNode() -> SCNNode {
        let geometries: [SCNGeometry] = [
            SCNSphere(radius: 0.05),
            SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01),
            SCNCylinder(radius: 0.05, height: 0.1)
        ]
        
        let randomGeometry = geometries.randomElement()!
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.random
        
        randomGeometry.materials = [material]
        
        let node = SCNNode(geometry: randomGeometry)
        
        return node
    }
    
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session failed with error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("AR session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("AR session interruption ended")
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Tracking not available")
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                print("Tracking limited: Excessive motion")
            case .insufficientFeatures:
                print("Tracking limited: Insufficient features")
            case .initializing:
                print("Tracking limited: Initializing")
            case .relocalizing:
                print("Tracking limited: Relocalizing")
            @unknown default:
                print("Tracking limited: Unknown reason")
            }
        case .normal:
            print("Tracking normal")
        @unknown default:
            print("Unknown tracking state")
        }
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
