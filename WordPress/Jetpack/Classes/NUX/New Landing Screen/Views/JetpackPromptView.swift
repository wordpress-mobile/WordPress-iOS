
import SwiftUI

struct JetpackPromptView: View {
    let data: JetpackPrompt
    let fontSize: CGFloat
    var body: some View {
        Text(data.text)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(data.color)
            .bold()
            .lineLimit(Constants.lineLimit)
            .padding(Constants.textInsets)
    }

    private enum Constants {
        static let lineLimit = 2
        static let textInsets = EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
    }

    /// Used to determine the available width for the text in this view
    static var totalHorizontalPadding: CGFloat {
        Constants.textInsets.leading + Constants.textInsets.trailing
    }
}
