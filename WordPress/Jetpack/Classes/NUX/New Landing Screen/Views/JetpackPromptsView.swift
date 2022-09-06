
import SwiftUI
import UIKit

struct JetpackPromptsView: View {
    @ObservedObject private var viewModel: JetpackPromptsViewModel

    init(viewModel: JetpackPromptsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(viewModel.prompts) { prompt in
                JetpackPromptView(data: prompt, fontSize: viewModel.fontSize)
                    .frame(height: prompt.frameHeight)
                    .offset(y: viewModel.offset(for: prompt))
                    .opacity(viewModel.opacity(for: prompt))
            }
        }
    }
}
