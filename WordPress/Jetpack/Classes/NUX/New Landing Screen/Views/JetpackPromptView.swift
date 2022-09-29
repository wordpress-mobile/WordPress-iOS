
import SwiftUI

struct JetpackPromptView: View {
    let data: JetpackPrompt
    let fontSize: CGFloat
    var body: some View {
        Text(data.text)
            .font(makeFont())
            .foregroundColor(data.color)
            .bold()
            .lineLimit(Constants.lineLimit)
            .padding(Constants.textInsets)
            .accessibility(hidden: true)
    }

    private func makeFont() -> Font {
        if #available(iOS 14.0, *) {
            return .system(size: fontSize, weight: .bold).leading(.tight)
        } else {
            return .system(size: fontSize, weight: .bold)
        }
    }

    private enum Constants {
        static let lineLimit = 2
        static let textInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
    }

    /// Used to determine the available width and height for the text in this view
    static let totalHorizontalPadding = Constants.textInsets.leading + Constants.textInsets.trailing
    static let totalVerticalPadding = Constants.textInsets.top + Constants.textInsets.bottom
}
