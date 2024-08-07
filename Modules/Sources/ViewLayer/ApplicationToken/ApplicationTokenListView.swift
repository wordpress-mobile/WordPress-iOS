import SwiftUI
import DesignSystem

public struct ApplicationTokenListView: View {

    let viewModel: ApplicationTokenListViewModel

    public init(dataProvider: ApplicationTokenListDataProvider) {
        self.viewModel = ApplicationTokenListViewModel(dataProvider: dataProvider)
    }

    package init(applicationTokens: [ApplicationTokenItem]) {
        self.viewModel = ApplicationTokenListViewModel(applicationTokens: applicationTokens)
    }

    public var body: some View {
        List(viewModel.applicationTokens) { token in
            ApplicationTokenListItemView(item: token)
        }
        .navigationTitle("Application Tokens")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Add Application Token", systemImage: "plus", action: {
                    print("About tapped!")
                })
            }
        }.onAppear(perform: {
            Task {

            }
        })
    }
}

class ApplicationTokenListViewModel: ObservableObject {

    @Published
    var isLoadingData: Bool = false

    @Published
    var applicationTokens: [ApplicationTokenItem]

    private let dataProvider: ApplicationTokenListDataProvider!

    init(dataProvider: ApplicationTokenListDataProvider) {
        self.dataProvider = dataProvider
        self.applicationTokens = []
    }

    init(applicationTokens: [ApplicationTokenItem]) {
        self.dataProvider = nil
        self.applicationTokens = applicationTokens
    }
}

#Preview {
    NavigationView {
        ApplicationTokenListView(applicationTokens: .testTokens)
    }
}
