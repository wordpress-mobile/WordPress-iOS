import SwiftUI

struct JetpackLandingScreenView: View {

    private let prompts = JetpackPromptsConfiguration.Constants.basePrompts
    private let evenColor = JetpackPromptsConfiguration.Constants.evenColor
    private let oddColor = JetpackPromptsConfiguration.Constants.oddColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<prompts.count * 2, id: \.hashValue) { index in
                JetpackPromptView(
                    text: prompts[index % prompts.count],
                    color: index % 2 == 0 ? evenColor : oddColor
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
