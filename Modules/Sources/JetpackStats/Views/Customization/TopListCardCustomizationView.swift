import SwiftUI

struct TopListCardCustomizationView: View {
    let topListViewModel: TopListViewModel

    @State private var selectedItem: TopListItemType?
    @State private var searchText = ""
    @State private var editMode: EditMode = .active

    @ScaledMetric private var iconWidth = 26

    @Environment(\.context) var context
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            if !searchText.isEmpty {
                filteredItemsList
            } else {
                groupedItemsList
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Buttons.cancel) {
                    topListViewModel.isEditing = false
                    dismiss()
                }
            }
        }
        .onAppear {
            selectedItem = topListViewModel.configuration.item
        }
        .onChange(of: selectedItem) { newValue in
            if let newValue {
                updateConfiguration(with: newValue)
            }
        }
    }
    
    @ViewBuilder
    private var groupedItemsList: some View {
        ForEach(Array(topListViewModel.groupedItems.enumerated()), id: \.offset) { _, items in
            Section {
                ForEach(items) { item in
                    itemRow(item: item)
                }
            }
        }
    }
    
    @ViewBuilder
    private var filteredItemsList: some View {
        let filteredItems = topListViewModel.items.filter { item in
            item.localizedTitle.localizedCaseInsensitiveContains(searchText)
        }
        
        ForEach(filteredItems) { item in
            itemRow(item: item)
        }
    }
    
    private func itemRow(item: TopListItemType) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedItem = item
            }
        }) {
            HStack(spacing: Constants.step0_5) {
                Image(systemName: selectedItem == item ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedItem == item ? .accentColor : Color(.tertiaryLabel))
                    .padding(.trailing, 8)

                Image(systemName: item.systemImage)
                    .font(.subheadline)
                    .frame(width: iconWidth)

                Text(item.localizedTitle)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func updateConfiguration(with item: TopListItemType) {
        var updatedConfig = topListViewModel.configuration
        updatedConfig.item = item
        
        // Adjust metric if current metric is not supported for the new item
        let supportedMetrics = context.service.getSupportedMetrics(for: item)
        if !supportedMetrics.contains(updatedConfig.metric),
           let firstMetric = supportedMetrics.first {
            updatedConfig.metric = firstMetric
        }
        
        topListViewModel.updateConfiguration(updatedConfig)
        topListViewModel.isEditing = false
        
        dismiss()
    }
}
