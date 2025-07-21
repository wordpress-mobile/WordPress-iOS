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
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
