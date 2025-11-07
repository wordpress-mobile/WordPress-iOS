import SwiftUI
import WordPressUI

struct TopListCardCustomizationView: View {
    let viewModel: TopListViewModel

    @State private var selectedItem: TopListItemType?
    @State private var searchText = ""
    @State private var editMode: EditMode = .active

    @ScaledMetric private var iconWidth = 26

    @Environment(\.context) var context
    @Environment(\.dismiss) var dismiss

    init(viewModel: TopListViewModel) {
        self.viewModel = viewModel
        self._selectedItem = State(initialValue: viewModel.configuration.item)
    }

    var body: some View {
        List {
            if !searchText.isEmpty {
                filteredItemsList
            } else {
                ForEach(viewModel.items) { item in
                    itemRow(item: item)
                }
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Buttons.cancel) {
                    viewModel.isEditing = false
                    dismiss()
                }
            }
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            if let newValue {
                updateConfiguration(with: newValue)
            }
        }
    }

    @ViewBuilder
    private var filteredItemsList: some View {
        let filteredItems = viewModel.items.filter { item in
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
                Image(systemName: item.systemImage)
                    .font(.subheadline)
                    .frame(width: iconWidth)

                Text(item.localizedTitle)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Image(systemName: selectedItem == item ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedItem == item ? .accentColor : Color(.tertiaryLabel))
                    .padding(.trailing, 8)
                    .opacity(selectedItem == item ? 1 : 0) // Reserve space
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }

    private func updateConfiguration(with item: TopListItemType) {
        var updatedConfig = viewModel.configuration
        updatedConfig.item = item

        // Adjust metric if current metric is not supported for the new item
        let supportedMetrics = context.service.getSupportedMetrics(for: item)
        if !supportedMetrics.contains(updatedConfig.metric),
           let firstMetric = supportedMetrics.first {
            updatedConfig.metric = firstMetric
        }

        viewModel.updateConfiguration(updatedConfig)
        viewModel.isEditing = false

        dismiss()
    }
}
