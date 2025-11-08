//
//  PhotoPreviewView.swift
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

struct PhotoPreviewView: View {
    let image: PlatformImage
    let onSave: () -> Void
    let onRetake: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Button(action: onRetake) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Retake")
                        }
                        .foregroundColor(.white)
                        .font(.body)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: onSave) {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Save")
                        }
                        .foregroundColor(.white)
                        .font(.body)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(20)
                    }
                    .padding()
                }
                .background(Color.black.opacity(0.7))
                
                // Image preview
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                #endif
            }
        }
    }
}

