//
//  CameraView.swift
//  testcam
//
//  Created by Dixit Solanki on 2025-11-08.
//

import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CameraView: View {
    @Binding var capturedImage: PlatformImage?
    @Binding var isCapturing: Bool
    
    var body: some View {
        #if os(iOS)
        CameraViewiOS(capturedImage: $capturedImage, isCapturing: $isCapturing)
        #elseif os(macOS)
        CameraViewmacOS(capturedImage: $capturedImage, isCapturing: $isCapturing)
        #endif
    }
}

#if os(iOS)
typealias PlatformImage = UIImage
typealias PlatformViewController = UIViewController
typealias PlatformView = UIView

struct CameraViewiOS: UIViewControllerRepresentable {
    @Binding var capturedImage: PlatformImage?
    @Binding var isCapturing: Bool
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        context.coordinator.setupNotificationObserver(for: controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // Update is not needed for notification-based approach
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraViewiOS
        private var notificationObserver: NSObjectProtocol?
        
        init(_ parent: CameraViewiOS) {
            self.parent = parent
            super.init()
        }
        
        func setupNotificationObserver(for controller: CameraViewController) {
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .capturePhoto,
                object: nil,
                queue: .main
            ) { [weak controller] _ in
                print("Notification received - triggering photo capture")
                controller?.capturePhoto()
            }
        }
        
        deinit {
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func didCaptureImage(_ image: PlatformImage) {
            print("Photo captured successfully!")
            DispatchQueue.main.async {
                self.parent.capturedImage = image
                self.parent.isCapturing = false
            }
        }
    }
}

#elseif os(macOS)
typealias PlatformImage = NSImage
typealias PlatformViewController = NSViewController
typealias PlatformView = NSView

struct CameraViewmacOS: NSViewControllerRepresentable {
    @Binding var capturedImage: PlatformImage?
    @Binding var isCapturing: Bool
    
    func makeNSViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        context.coordinator.setupNotificationObserver(for: controller)
        return controller
    }
    
    func updateNSViewController(_ nsViewController: CameraViewController, context: Context) {
        // Update is not needed for notification-based approach
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraViewmacOS
        private var notificationObserver: NSObjectProtocol?
        
        init(_ parent: CameraViewmacOS) {
            self.parent = parent
            super.init()
        }
        
        func setupNotificationObserver(for controller: CameraViewController) {
            notificationObserver = NotificationCenter.default.addObserver(
                forName: .capturePhoto,
                object: nil,
                queue: .main
            ) { [weak controller] _ in
                print("Notification received - triggering photo capture")
                controller?.capturePhoto()
            }
        }
        
        deinit {
            if let observer = notificationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        func didCaptureImage(_ image: PlatformImage) {
            print("Photo captured successfully!")
            DispatchQueue.main.async {
                self.parent.capturedImage = image
                self.parent.isCapturing = false
            }
        }
    }
}
#endif

protocol CameraViewControllerDelegate: AnyObject {
    func didCaptureImage(_ image: PlatformImage)
}

class CameraViewController: PlatformViewController {
    weak var delegate: CameraViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCapturePhotoOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private var isCapturingPhoto = false
    
    #if os(iOS)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSessionIfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSessionIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoPreviewLayer?.frame = view.bounds
    }
    #elseif os(macOS)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        startSessionIfNeeded()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        stopSessionIfNeeded()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        videoPreviewLayer?.frame = view.bounds
    }
    #endif
    
    func startSessionIfNeeded() {
        if captureSession != nil && !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    func stopSessionIfNeeded() {
        if captureSession != nil && captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        var camera: AVCaptureDevice?
        
        #if os(iOS)
        // iOS: Try back camera first, then front camera
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            camera = backCamera
        } else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            camera = frontCamera
        } else {
            // Fallback: try default video device (works on Mac Catalyst)
            camera = AVCaptureDevice.default(for: .video)
        }
        #elseif os(macOS)
        // macOS: First try to get default video device
        camera = AVCaptureDevice.default(for: .video)
        
        // If no default, discover available cameras
        if camera == nil {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
                mediaType: .video,
                position: .unspecified
            )
            camera = discoverySession.devices.first
            print("Found \(discoverySession.devices.count) camera(s)")
            for device in discoverySession.devices {
                print("Camera: \(device.localizedName)")
            }
        }
        #endif
        
        guard let camera = camera else {
            print("Unable to access camera! No camera found.")
            DispatchQueue.main.async {
                // You could show an error message to the user here
            }
            return
        }
        
        print("Using camera: \(camera.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            stillImageOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            } else {
                print("Cannot add input or output to capture session")
            }
        } catch {
            print("Error setting up camera input: \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        
        #if os(iOS)
        videoPreviewLayer.connection?.videoOrientation = .portrait
        #elseif os(macOS)
        // macOS doesn't need orientation adjustment for preview
        #endif
        
        #if os(iOS)
        view.layer.addSublayer(videoPreviewLayer)
        #elseif os(macOS)
        if view.layer == nil {
            view.layer = CALayer()
        }
        view.wantsLayer = true
        view.layer?.addSublayer(videoPreviewLayer)
        #endif
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async {
                self?.videoPreviewLayer.frame = self?.view.bounds ?? .zero
            }
        }
    }
    
    func capturePhoto() {
        print("capturePhoto() called")
        print("isCapturingPhoto: \(isCapturingPhoto)")
        print("stillImageOutput: \(stillImageOutput != nil ? "exists" : "nil")")
        print("captureSession.isRunning: \(captureSession?.isRunning ?? false)")
        
        guard let output = stillImageOutput else {
            print("Error: stillImageOutput is nil")
            return
        }
        
        guard !isCapturingPhoto else {
            print("Warning: Already capturing a photo")
            return
        }
        
        guard captureSession?.isRunning == true else {
            print("Error: Capture session is not running")
            return
        }
        
        isCapturingPhoto = true
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        
        // Ensure settings are compatible with the output
        if output.availablePhotoCodecTypes.contains(.jpeg) {
            output.capturePhoto(with: settings, delegate: self)
            print("Photo capture initiated")
        } else {
            print("Error: JPEG codec not available")
            isCapturingPhoto = false
        }
    }
}
//Bhosdino

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto called")
        isCapturingPhoto = false
        
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error: Could not get image data representation")
            return
        }
        
        print("Image data size: \(imageData.count) bytes")
        
        #if os(iOS)
        if let image = UIImage(data: imageData) {
            print("Successfully created UIImage")
            delegate?.didCaptureImage(image)
        } else {
            print("Error: Could not create UIImage from data")
        }
        #elseif os(macOS)
        if let image = NSImage(data: imageData) {
            print("Successfully created NSImage")
            delegate?.didCaptureImage(image)
        } else {
            print("Error: Could not create NSImage from data")
        }
        #endif
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error in didFinishCaptureFor: \(error.localizedDescription)")
        } else {
            print("Photo capture finished successfully")
        }
    }
}

