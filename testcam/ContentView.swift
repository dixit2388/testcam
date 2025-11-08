//
//  ContentView.swift
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

extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
}

enum AppView {
    case camera
    case preview
    case gallery
}

struct ContentView: View {
    @State private var capturedImage: PlatformImage?
    @State private var isCapturing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentView: AppView = .camera
    @State private var showSavedAlert = false
    @ObservedObject var photoStorage = PhotoStorage.shared
    
    var body: some View {
        Group {
            switch currentView {
            case .camera:
                cameraView
            case .preview:
                if let image = capturedImage {
                    PhotoPreviewView(
                        image: image,
                        onSave: {
                            savePhoto(image)
                        },
                        onRetake: {
                            capturedImage = nil
                            currentView = .camera
                        },
                        onDismiss: {
                            capturedImage = nil
                            currentView = .camera
                        }
                    )
                } else {
                    cameraView
                }
            case .gallery:
                ZStack {
                    PhotoGalleryView()
                    
                    VStack {
                        HStack {
                            Button(action: {
                                currentView = .camera
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                    Text("Camera")
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(20)
                            }
                            .padding()
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .alert("Camera Access", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Photo Saved", isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Photo has been saved to your gallery!")
        }
        .onAppear {
            checkCameraPermission()
            photoStorage.loadPhotos()
        }
        .onChange(of: capturedImage) { newValue in
            if newValue != nil {
                currentView = .preview
            }
        }
        .onChange(of: isCapturing) { newValue in
            if newValue {
                print("isCapturing changed to true - posting capture notification")
                NotificationCenter.default.post(name: .capturePhoto, object: nil)
            }
        }
    }
    
    var cameraView: some View {
        ZStack {
            CameraView(capturedImage: $capturedImage, isCapturing: $isCapturing)
                .ignoresSafeArea()
            
            VStack {
                // Top toolbar
                HStack {
                    Spacer()
                    
                    Button(action: {
                        photoStorage.loadPhotos()
                        currentView = .gallery
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 50, height: 50)
                            
                            if let lastPhoto = photoStorage.photos.first {
                                #if os(iOS)
                                Image(uiImage: lastPhoto.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                #elseif os(macOS)
                                Image(nsImage: lastPhoto.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                #endif
                                
                                // Photo count badge
                                if photoStorage.photos.count > 0 {
                                    Text("\(photoStorage.photos.count)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 18, y: -18)
                                }
                            } else {
                                Image(systemName: "photo.on.rectangle")
                                    .foregroundColor(.white)
                                    .font(.title3)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Capture button
                Button(action: {
                    print("Capture button tapped")
                    isCapturing = true
                    // Force a state update to ensure the view updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // This ensures the state change is processed
                    }
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 3)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    func savePhoto(_ image: PlatformImage) {
        if let _ = photoStorage.savePhoto(image) {
            photoStorage.loadPhotos() // Reload to update the gallery button thumbnail
            showSavedAlert = true
            capturedImage = nil
            // Don't change view immediately - let user see the alert first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentView = .camera
            }
        }
    }
    
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        alertMessage = "Camera access is required to use this app. Please enable it in Settings."
                        showAlert = true
                    }
                }
            }
        case .denied, .restricted:
            alertMessage = "Camera access is denied. Please enable it in Settings."
            showAlert = true
        @unknown default:
            break
        }
    }
}

#Preview {
    ContentView()
}
