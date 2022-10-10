import SwiftUI

struct JetpackLandingScreenView: View {
    /// If the view should start with the even color, set to `true`.
    let startWithEvenColor: Bool

    private let prompts = JetpackPromptsConfiguration.Constants.basePrompts
    private let evenColor = JetpackPromptsConfiguration.Constants.evenColor
    private let oddColor = JetpackPromptsConfiguration.Constants.oddColor

    func colorForIndex(_ index: Int) -> Color {
        let colorOffset = startWithEvenColor ? 0 : 1
        return (index + colorOffset) % 2 == 0 ? evenColor : oddColor
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<prompts.count, id: \.hashValue) { index in
                JetpackPromptView(text: prompts[index], color: colorForIndex(index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
