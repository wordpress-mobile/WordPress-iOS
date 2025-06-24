import SwiftUI

/// A reusable card view component that provides a consistent container style
/// with optional title and customizable content.
public struct CardView<Content: View>: View {
    let title: String?
    @ViewBuilder let content: () -> Content

    public init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title {
                Text(title.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }
}

#Preview("With Title") {
    CardView("Section Title") {
        VStack(alignment: .leading, spacing: 12) {
            Text("Card Content")
            Text("More content here")
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}

#Preview("Without Title") {
    CardView {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
            Text("Featured Item")
            Spacer()
        }
    }
    .padding()
}
