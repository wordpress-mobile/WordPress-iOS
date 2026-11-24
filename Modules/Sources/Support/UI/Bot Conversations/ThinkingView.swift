import SwiftUI

struct ThinkingView: View {

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            // Thinking text with shimmer effect
            Text(Localization.thinking)
                .font(.body.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .shimmer()
    }
}

#Preview {
    ThinkingView().padding()
}
