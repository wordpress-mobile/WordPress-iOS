import SwiftUI

struct SimpleErrorView: View {
    let message: String

    init(message: String) {
        self.message = message
    }

    init(error: Error) {
        self.message = error.localizedDescription
    }

    var body: some View {
        Text(message)
            .font(.body.weight(.medium))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityLabel(Strings.Accessibility.errorLoadingStats)
            .accessibilityValue(message)
    }
}
