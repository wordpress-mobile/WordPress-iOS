import SwiftUI
import WordPressUI

@MainActor
struct PostSettingsSocialSharingRow: View {
    @ObservedObject var viewModel: PostSettingsSocialSharingViewModel

    var body: some View {
        switch viewModel.state {
        case .noConnection(let viewModel):
            JetpackSocialNoConnectionView(viewModel: viewModel)
        case .hasConnections(let viewModel):
            autoSharingView(viewModel: viewModel)
        case .hidden:
            EmptyView()
        }
    }

    @ViewBuilder
    private func autoSharingView(viewModel model: PrepublishingAutoSharingModel) -> some View {
        NavigationLink {
            PostSettingsSocialAccountsView(
                blogID: viewModel.blogID ?? 0,
                model: model,
                delegate: viewModel,
                coreDataStack: viewModel.coreDataStack
            )
            .ignoresSafeArea()
        } label: {
            PrepublishingAutoSharingView(model: model)
        }
    }
}
