//
//  FaceDetactViewController.swift
//  ARTreckingDemo
//
//  Created by Arpit iOS Dev. on 11/07/24.
//

import UIKit
import ARKit
import FirebaseMLVision

class FaceTrackingViewController: UIViewController, ARSCNViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private var vision = Vision.vision()
    private var faceDetector: VisionFaceDetector!

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session = ARSession()
        sceneView.automaticallyUpdatesLighting = true

        setupFaceDetector()
        setupCamera()
    }

    private func setupFaceDetector() {
        let options = VisionFaceDetectorOptions()
        options.performanceMode = .accurate
        options.landmarkMode = .all
        options.classificationMode = .all

        faceDetector = vision.faceDetector(options: options)
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

    // ARSCNViewDelegate methods
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }
        let node = SCNNode()

        // Add the glasses model
        let glassesNode = createGlassesNode()
        node.addChildNode(glassesNode)

        return node
    }

    private func createGlassesNode() -> SCNNode {
        let glassesScene = SCNScene(named: "art.scnassets/glasses.scn")!
        let glassesNode = glassesScene.rootNode.childNode(withName: "glasses", recursively: true)!
        glassesNode.position = SCNVector3(0, 0, 0.1) // Adjust the position as necessary
        return glassesNode
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = .rightTop

        detectFaces(in: visionImage)
    }

    private func detectFaces(in image: VisionImage) {
        faceDetector.process(image) { faces, error in
            guard error == nil, let faces = faces, !faces.isEmpty else {
                // Handle error or no faces detected
                return
            }

            DispatchQueue.main.async {
                // Update AR scene with detected faces
                self.updateARScene(with: faces)
            }
        }
    }

    private func updateARScene(with faces: [VisionFace]) {
        guard let faceAnchor = sceneView.session.currentFrame?.anchors.first as? ARFaceAnchor else { return }
        let node = sceneView.node(for: faceAnchor)
        node?.childNodes.forEach { $0.removeFromParentNode() }

        for face in faces {
            let glassesNode = createGlassesNode()
            node?.addChildNode(glassesNode)
        }
    }
}
