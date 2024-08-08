import SwiftUI

public struct AcknowledgementsListView: View {

    @ObservedObject
    var viewModel: AcknowledgementsListViewModel

    public init(viewModel: AcknowledgementsListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if let error = viewModel.error {
                EmptyStateView(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                    .multilineTextAlignment(.center)
            } else if viewModel.isLoadingItems {
                ProgressView()
            } else {
                List(viewModel.items) { item in
                    NavigationLink {
                        AcknowledgementsDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.body)
                            if let description = item.description {
                                Text(description)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Strings.acknowledgementsTitle)
        .task { await viewModel.loadItems() }
    }

    private enum Strings {
        static let acknowledgementsTitle = NSLocalizedString(
            "acknowledgements.title",
            value: "Acknowledgements",
            comment: "The title for the list of third-party software we use"
        )
    }
}

#Preview {
    NavigationView {
        AcknowledgementsListView(viewModel: AcknowledgementsListViewModel.withSampleData())
    }
}
