import SwiftUI

struct LockScreenFieldView: View {
    let title: String
    let value: Int

    private var accessibilityLabel: Text {
        Text(title) + Text(": ") + Text(value.abbreviatedString())
    }

    var body: some View {
        VStack {
            Text(value.abbreviatedString())
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 20, weight: .bold))
                .minimumScaleFactor(0.8)
                .foregroundColor(.white)
                .lineLimit(1)
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.system(size: 10))
                .lineLimit(1)
        }
    }
}
