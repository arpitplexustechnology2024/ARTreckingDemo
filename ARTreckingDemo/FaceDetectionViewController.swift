//
//  FaceDetectionViewController.swift
//  ARTreckingDemo
//
//  Created by Arpit iOS Dev. on 11/07/24.
//

import UIKit
import AVFoundation
import MLKitFaceDetection
import MLKitVision

class FaceDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var captureSession: AVCaptureSession!
    private var faceDetector: FaceDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCamera()
        setupFaceDetector()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("Error: No video capture device available")
            return
        }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error creating video input: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            print("Error: Cannot add video input")
            return
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Error: Cannot add video output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func setupFaceDetector() {
        let options = FaceDetectorOptions()
        options.performanceMode = .fast
        options.landmarkMode = .all
        options.classificationMode = .all
        
        faceDetector = FaceDetector.faceDetector(options: options)
        
        print("FaceDetector initialized: \(faceDetector != nil)")
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let faceDetector = faceDetector else {
            print("Error: faceDetector is nil")
            return
        }
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        visionImage.orientation = imageOrientation(from: UIDevice.current.orientation, cameraPosition: .front)
        
        faceDetector.process(visionImage) { [weak self] faces, error in
            guard let self = self else { return }  // Ensure self is not nil
            guard error == nil, let faces = faces, !faces.isEmpty else {
                // Handle error or no faces detected
                return
            }
            
            // Process detected faces
            DispatchQueue.main.async {
                self.handleFaces(faces)
            }
        }
    }
    
    private func imageOrientation(from deviceOrientation: UIDeviceOrientation, cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return cameraPosition == .back ? .leftMirrored : .right
        case .landscapeLeft:
            return cameraPosition == .back ? .downMirrored : .up
        case .portraitUpsideDown:
            return cameraPosition == .back ? .rightMirrored : .left
        case .landscapeRight:
            return cameraPosition == .back ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        }
    }
    
    private func handleFaces(_ faces: [Face]) {
        // Clear previous face rectangles
        for subview in view.subviews {
            if subview.tag == 100 {
                subview.removeFromSuperview()
            }
        }
        
        for face in faces {
            let frame = face.frame
            
            let faceView = UIView(frame: frame)
            faceView.layer.borderColor = UIColor.red.cgColor
            faceView.layer.borderWidth = 2
            faceView.tag = 100
            faceView.backgroundColor = .clear
            
            view.addSubview(faceView)
            
            if face.hasSmilingProbability {
                print("Smiling Probability: \(face.smilingProbability)")
            }
            if face.hasLeftEyeOpenProbability {
                print("Left Eye Open Probability: \(face.leftEyeOpenProbability)")
            }
        }
    }
}
