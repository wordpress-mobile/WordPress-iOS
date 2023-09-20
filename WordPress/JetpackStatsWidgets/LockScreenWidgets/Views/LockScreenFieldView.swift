import SwiftUI

struct LockScreenFieldView: View {
    struct ValueFontSize {
        static let `default`: CGFloat = 20
        static let medium: CGFloat = 18
        static let small: CGFloat = 16
    }

    let title: String
    let value: String
    let valueFontSize: CGFloat

    init(title: String, value: String, valueFontSize: CGFloat = ValueFontSize.default) {
        self.title = title
        self.value = value
        self.valueFontSize = valueFontSize
    }


    private var accessibilityLabel: Text {
        Text(title) + Text(": ") + Text(value)
    }

    var body: some View {
        VStack {
            Spacer(minLength: 0)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: valueFontSize, weight: .bold))
                .minimumScaleFactor(0.6)
                .foregroundColor(.white)
                .allowsTightening(true)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 10))
                .minimumScaleFactor(0.9)
                .allowsTightening(true)
                .lineLimit(1)
        }
    }
}
