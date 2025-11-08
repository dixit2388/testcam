//
//  PhotoStorage.swift
//  testcam
//
//  Created by Dixit Solanki on 2025-11-08.
//

import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class PhotoStorage: ObservableObject {
    static let shared = PhotoStorage()
    
    @Published var photos: [PhotoItem] = []
    
    private let photosDirectory: URL
    private let fileManager = FileManager.default
    
    struct PhotoItem: Identifiable {
        let id: UUID
        let image: PlatformImage
        let date: Date
        let fileURL: URL
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private init() {
        // Get documents directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        photosDirectory = documentsPath.appendingPathComponent("CapturedPhotos")
        
        // Create photos directory if it doesn't exist
        createPhotosDirectoryIfNeeded()
        
        // Load existing photos
        loadPhotos()
    }
    
    private func createPhotosDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            try? fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }
    
    func savePhoto(_ image: PlatformImage) -> UUID? {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)
        
        #if os(iOS)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data")
            return nil
        }
        #elseif os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let imageData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            print("Failed to convert image to JPEG data")
            return nil
        }
        #endif
        
        do {
            try imageData.write(to: fileURL)
            let photoItem = PhotoItem(id: id, image: image, date: Date(), fileURL: fileURL)
            
            DispatchQueue.main.async {
                self.photos.insert(photoItem, at: 0) // Add to beginning
            }
            
            print("Photo saved: \(fileURL.path)")
            return id
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }
    
    func loadPhotos() {
        photos = []
        
        guard let files = try? fileManager.contentsOfDirectory(at: photosDirectory, includingPropertiesForKeys: [.creationDateKey]) else {
            print("Failed to read photos directory")
            return
        }
        
        let imageFiles = files.filter { $0.pathExtension.lowercased() == "jpg" || $0.pathExtension.lowercased() == "jpeg" }
        
        var loadedPhotos: [PhotoItem] = []
        
        for fileURL in imageFiles {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let creationDate = attributes[.creationDate] as? Date {
                #if os(iOS)
                if let image = UIImage(contentsOfFile: fileURL.path) {
                    let id = UUID(uuidString: fileURL.deletingPathExtension().lastPathComponent) ?? UUID()
                    let photoItem = PhotoItem(id: id, image: image, date: creationDate, fileURL: fileURL)
                    loadedPhotos.append(photoItem)
                }
                #elseif os(macOS)
                if let image = NSImage(contentsOfFile: fileURL.path) {
                    let id = UUID(uuidString: fileURL.deletingPathExtension().lastPathComponent) ?? UUID()
                    let photoItem = PhotoItem(id: id, image: image, date: creationDate, fileURL: fileURL)
                    loadedPhotos.append(photoItem)
                }
                #endif
            }
        }
        
        // Sort by date (newest first)
        loadedPhotos.sort { $0.date > $1.date }
        
        DispatchQueue.main.async {
            self.photos = loadedPhotos
        }
    }
    
    func deletePhoto(_ photo: PhotoItem) {
        do {
            try fileManager.removeItem(at: photo.fileURL)
            DispatchQueue.main.async {
                self.photos.removeAll { $0.id == photo.id }
            }
            print("Photo deleted: \(photo.fileURL.path)")
        } catch {
            print("Failed to delete photo: \(error)")
        }
    }
    
    func deleteAllPhotos() {
        for photo in photos {
            try? fileManager.removeItem(at: photo.fileURL)
        }
        DispatchQueue.main.async {
            self.photos = []
        }
    }
}

