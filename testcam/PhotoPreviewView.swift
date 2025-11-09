import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PhotoPreviewView: View {
    private let originalImage: Platform.Image
    let onSave: (Platform.Image) -> Void
    let onRetake: () -> Void
    let onDismiss: () -> Void
    
    @State private var selectedFilter: PhotoFilter
    @State private var previewImage: Platform.Image
    
    init(image: Platform.Image,
         initialFilter: PhotoFilter,
         onSave: @escaping (Platform.Image) -> Void,
         onRetake: @escaping () -> Void,
         onDismiss: @escaping () -> Void) {
        self.originalImage = image
        self.onSave = onSave
        self.onRetake = onRetake
        self.onDismiss = onDismiss
        _selectedFilter = State(initialValue: initialFilter)
        _previewImage = State(initialValue: initialFilter.apply(to: image))
    }
    
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
                    
                    Button(action: {
                        onSave(previewImage)
                    }) {
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
                Group {
                    #if os(iOS)
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #elseif os(macOS)
                    Image(nsImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #endif
                }
                .padding(.horizontal)
                
                // Filter controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filters")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.leading)
                    
                    FilterPicker(selectedFilter: $selectedFilter) { filter in
                        previewImage = filter.apply(to: originalImage)
                    }
                    .padding(.bottom, 20)
                }
                .background(Color.black.opacity(0.85))
            }
        }
    }
}
