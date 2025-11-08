//
//  PhotoGalleryView.swift
//  testcam
//
//  Created by Dixit Solanki on 2025-11-08.
//

import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PhotoGalleryView: View {
    @ObservedObject var photoStorage = PhotoStorage.shared
    @State private var selectedPhoto: PhotoStorage.PhotoItem?
    @State private var showDeleteConfirmation = false
    @State private var photoToDelete: PhotoStorage.PhotoItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 2)
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Text("Gallery")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                    
                    Spacer()
                    
                    if !photoStorage.photos.isEmpty {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.title3)
                                .padding()
                        }
                    }
                }
                .background(Color.black.opacity(0.8))
                
                if photoStorage.photos.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No photos yet")
                            .foregroundColor(.gray)
                            .font(.title2)
                        Text("Capture some photos to see them here")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photoStorage.photos) { photo in
                                PhotoThumbnailView(photo: photo) {
                                    selectedPhoto = photo
                                }
                            }
                        }
                        .padding(2)
                    }
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo)
        }
        .alert("Delete All Photos", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                photoStorage.deleteAllPhotos()
            }
        } message: {
            Text("Are you sure you want to delete all photos? This action cannot be undone.")
        }
        .onAppear {
            photoStorage.loadPhotos()
        }
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoStorage.PhotoItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            #if os(iOS)
            Image(uiImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(4)
            #elseif os(macOS)
            Image(nsImage: photo.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipped()
                .cornerRadius(4)
            #endif
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PhotoDetailView: View {
    let photo: PhotoStorage.PhotoItem
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Top toolbar
                HStack {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.title2)
                            .padding()
                    }
                }
                
                Spacer()
                
                // Full image
                #if os(iOS)
                Image(uiImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #elseif os(macOS)
                Image(nsImage: photo.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
                
                Spacer()
                
                // Photo info
                Text(photo.formattedDate)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .alert("Delete Photo", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                PhotoStorage.shared.deletePhoto(photo)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this photo?")
        }
    }
}

