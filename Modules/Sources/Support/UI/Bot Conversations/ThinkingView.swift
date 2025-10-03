import SwiftUI

struct ThinkingView: View {

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            // Thinking text with shimmer effect
            Text("Thinking...")
                .font(.system(size: 16, weight: .medium))
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
