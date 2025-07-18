import SwiftUI

struct SimpleErrorView: View {
    let error: Error

    var body: some View {
        Text(error.localizedDescription)
            .font(.subheadline.weight(.medium))
            .multilineTextAlignment(.center)
            .frame(maxWidth: 300)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
