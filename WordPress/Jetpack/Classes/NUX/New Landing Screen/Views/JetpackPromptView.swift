import SwiftUI

struct JetpackPromptView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(makeFont())
            .lineLimit(Constants.lineLimit)
            .padding(Constants.textInsets)
            .accessibility(hidden: true)
    }

    private func makeFont() -> Font {
        if #available(iOS 14.0, *) {
            return .system(size: Constants.fontSize, weight: .bold)
        } else {
            return .system(size: Constants.fontSize, weight: .bold)
        }
    }

    private enum Constants {
        static let lineLimit = 2
        static let textInsets = EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16)
        static let fontSize: CGFloat = 45
    }
}
