//
//  CameraView.swift
//  testcam
//
//  Created by Dixit Solanki on 2025-11-08.
//

import SwiftUI
import AVFoundation
import CoreImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Platform {
    #if os(iOS)
    typealias Image = UIImage
    typealias ViewController = UIViewController
    typealias View = UIView
    typealias Color = UIColor
    #elseif os(macOS)
    typealias Image = NSImage
    typealias ViewController = NSViewController
    typealias View = NSView
    typealias Color = NSColor
    #endif
}

enum PhotoFilter: String, CaseIterable, Identifiable {
    case original
    case sepia
    case noir
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .original: return "Original"
        case .sepia: return "Warm"
        case .noir: return "Noir"
        }
    }
    
    func apply(to image: Platform.Image) -> Platform.Image {
        switch self {
        case .original:
            return image
        case .sepia:
            return PhotoFilterProcessor.shared.applyFilter(named: "CISepiaTone", intensity: 0.9, to: image)
        case .noir:
            return PhotoFilterProcessor.shared.applyFilter(named: "CIPhotoEffectNoir", to: image)
        }
    }
}

final class PhotoFilterProcessor {
    static let shared = PhotoFilterProcessor()
    private let context = CIContext()
    
    private init() {}
    
    func applyFilter(named name: String, intensity: Float? = nil, to image: Platform.Image) -> Platform.Image {
        guard let ciImage = makeCIImage(from: image),
              let filter = CIFilter(name: name) else {
            return image
        }
        
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        if let intensity = intensity {
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
        }
        
        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
        #endif
    }
    
    private func makeCIImage(from image: Platform.Image) -> CIImage? {
        #if os(iOS)
        return CIImage(image: image)
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return CIImage(bitmapImageRep: bitmap)
        #endif
    }
}

struct CameraView: View {
    @Binding var capturedImage: Platform.Image?
    @Binding var isCapturing: Bool
    @Binding var selectedFilter: PhotoFilter
    
    var body: some View {
        #if os(iOS)
        CameraViewIOS(capturedImage: $capturedImage, isCapturing: $isCapturing, selectedFilter: $selectedFilter)
        #elseif os(macOS)
        CameraViewMac(capturedImage: $capturedImage, isCapturing: $isCapturing, selectedFilter: $selectedFilter)
        #endif
    }
}

#if os(iOS)
private struct CameraViewIOS: UIViewControllerRepresentable {
    @Binding var capturedImage: Platform.Image?
    @Binding var isCapturing: Bool
    @Binding var selectedFilter: PhotoFilter
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.selectedFilter = selectedFilter
        if isCapturing {
            uiViewController.capturePhoto()
            DispatchQueue.main.async {
                isCapturing = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, CameraViewControllerDelegate {
        private let parent: CameraViewIOS
        
        init(_ parent: CameraViewIOS) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didCapture image: Platform.Image) {
            let filtered = parent.selectedFilter.apply(to: image)
            let bindingParent = parent
            DispatchQueue.main.async {
                bindingParent.capturedImage = filtered
                bindingParent.isCapturing = false
            }
        }
    }
}
#elseif os(macOS)
private struct CameraViewMac: NSViewControllerRepresentable {
    @Binding var capturedImage: Platform.Image?
    @Binding var isCapturing: Bool
    @Binding var selectedFilter: PhotoFilter
    
    func makeNSViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateNSViewController(_ nsViewController: CameraViewController, context: Context) {
        nsViewController.selectedFilter = selectedFilter
        if isCapturing {
            nsViewController.capturePhoto()
            DispatchQueue.main.async {
                isCapturing = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, CameraViewControllerDelegate {
        private let parent: CameraViewMac
        
        init(_ parent: CameraViewMac) {
            self.parent = parent
        }
        
        func cameraViewController(_ controller: CameraViewController, didCapture image: Platform.Image) {
            let filtered = parent.selectedFilter.apply(to: image)
            let bindingParent = parent
            DispatchQueue.main.async {
                bindingParent.capturedImage = filtered
            }
        }
    }
}
#endif

protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewController(_ controller: CameraViewController, didCapture image: Platform.Image)
}

#if os(iOS)
final class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    var selectedFilter: PhotoFilter = .original
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
        setupPreview()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    func capturePhoto() {
        guard session.isRunning else { return }
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)
        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        session.startRunning()
    }
    
    private func setupPreview() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.connection?.videoOrientation = .portrait
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }
        delegate?.cameraViewController(self, didCapture: image)
    }
}
#elseif os(macOS)
final class CameraViewController: NSViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    var selectedFilter: PhotoFilter = .original
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSession()
        setupPreview()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        previewLayer?.frame = view.bounds
    }
    
    func capturePhoto() {
        guard session.isRunning else { return }
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return
        }
        session.addInput(input)
        guard session.canAddOutput(photoOutput) else { return }
        session.addOutput(photoOutput)
        session.commitConfiguration()
        session.startRunning()
    }
    
    private func setupPreview() {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.wantsLayer = true
        view.layer?.addSublayer(layer)
        previewLayer = layer
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = NSImage(data: data) else {
            return
        }
        delegate?.cameraViewController(self, didCapture: image)
    }
}
#endif

