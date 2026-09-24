import SwiftUI

struct LockScreenFieldView: View {
    struct ValueFontSize {
        static let `default`: CGFloat = 22
        static let medium: CGFloat = 20
        static let small: CGFloat = 18
    }

    let title: String
    let value: String
    let spokenValue: String
    let valueFontSize: CGFloat

    init(title: String, value: String, spokenValue: String, valueFontSize: CGFloat = ValueFontSize.default) {
        self.title = title
        self.value = value
        self.spokenValue = spokenValue
        self.valueFontSize = valueFontSize
    }

    var body: some View {
        VStack {
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: valueFontSize, weight: .heavy))
                .minimumScaleFactor(0.9)
                .foregroundColor(.white)
                .allowsTightening(true)
                .lineLimit(1)
                .accessibilityLabel(Text(spokenValue))
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 11))
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .lineLimit(1)
        }
    }
}
