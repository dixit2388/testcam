import SwiftUI

struct FilterPicker: View {
    @Binding var selectedFilter: PhotoFilter
    var onSelect: ((PhotoFilter) -> Void)?
    
    private let filters = PhotoFilter.allCases
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters) { filter in
                    Button(action: {
                        selectedFilter = filter
                        onSelect?(filter)
                    }) {
                        Text(filter.displayName)
                            .font(.caption)
                            .fontWeight(filter == selectedFilter ? .bold : .regular)
                            .foregroundColor(filter == selectedFilter ? .black : .white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(filter == selectedFilter ? Color.white : Color.black.opacity(0.4))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(filter == selectedFilter ? 1 : 0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
