//
//  FaceDetactViewController.swift
//  ARTreckingDemo
//
//  Created by Arpit iOS Dev. on 11/07/24.
//

import UIKit
import ARKit
import MLKit
import AVFoundation

class FaceTrackingViewController: UIViewController, ARSCNViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    private var faceDetector: FaceDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session = ARSession()
        sceneView.automaticallyUpdatesLighting = true
        
        setupFaceDetector()
        setupCamera()
    }
    
    private func setupFaceDetector() {
        let options = FaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all
        
        faceDetector = FaceDetector.faceDetector(options: options)
    }
    
    private func setupCamera() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }
        let node = SCNNode()
        
        let glassesNode = createGlassesNode()
        node.addChildNode(glassesNode)
        
        return node
    }
    
    private func createGlassesNode() -> SCNNode {
        let glassesNode = SCNNode()
        
        let glassesPlane = SCNPlane(width: 0.13, height: 0.07)
        glassesPlane.firstMaterial?.diffuse.contents = UIImage(named: "glasses.png")
        
        let glassesPlaneNode = SCNNode(geometry: glassesPlane)
        glassesPlaneNode.position = SCNVector3(0, 0, 0.11)
        
        glassesNode.addChildNode(glassesPlaneNode)
        
        return glassesNode
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation(from: UIDevice.current.orientation)
        
        detectFaces(in: image)
    }
    
    private func detectFaces(in image: VisionImage) {
        faceDetector.process(image) { faces, error in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                return
            }
            
            DispatchQueue.main.async {
                self.updateARScene(with: faces)
            }
        }
    }
    
    private func updateARScene(with faces: [Face]) {
        guard let faceAnchor = sceneView.session.currentFrame?.anchors.first as? ARFaceAnchor else { return }
        let node = sceneView.node(for: faceAnchor)
        node?.childNodes.forEach { $0.removeFromParentNode() }
        
        for face in faces {
            let glassesNode = createGlassesNode()
            node?.addChildNode(glassesNode)
        }
    }
    
    private func imageOrientation(from deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return .right
        case .landscapeLeft:
            return .up
        case .portraitUpsideDown:
            return .left
        case .landscapeRight:
            return .down
        case .faceUp, .faceDown, .unknown:
            return .up
        @unknown default:
            return .up
        }
    }
}
