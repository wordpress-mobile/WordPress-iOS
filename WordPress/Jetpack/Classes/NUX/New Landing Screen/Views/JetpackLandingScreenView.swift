
import SwiftUI

struct JetpackLandingScreenView: View {

    let viewModel: JetpackPromptsViewModel

    var body: some View {
        GeometryReader { proxy in
            makeJetpackPromptsView(size: CGSize(width: proxy.size.width - JetpackPromptView.totalHorizontalPadding,
                                                height: proxy.size.height))
        }
    }

    private func makeJetpackPromptsView(size: CGSize) -> some View {
        viewModel.configuration = JetpackPromptsConfiguration(size: size)
        return JetpackPromptsView(viewModel: viewModel)
    }
}
