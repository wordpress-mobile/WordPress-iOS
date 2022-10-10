import SwiftUI

struct JetpackLandingScreenView: View {

    private let prompts = JetpackPromptsConfiguration.Constants.basePrompts
    private let evenColor = JetpackPromptsConfiguration.Constants.evenColor
    private let oddColor = JetpackPromptsConfiguration.Constants.oddColor

    private var loopCount: Int {
        if prompts.count % 2 == 0 {
            return prompts.count
        }

        /// The number of prompts is odd so we loop twice
        /// to prevent the same color from occurring when the view repeats.
        return prompts.count * 2
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<loopCount, id: \.hashValue) { index in
                JetpackPromptView(
                    text: prompts[index % prompts.count],
                    color: index % 2 == 0 ? evenColor : oddColor
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
