import SwiftUI
import DesignSystem

/// A reusable info row component that displays a title and customizable content.
/// Commonly used within cards or forms to display labeled information.
public struct InfoRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    public init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            content()
                .font(.subheadline.weight(.regular))
                .lineLimit(1)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Convenience Initializer

extension InfoRow where Content == Text {
    /// Convenience initializer for displaying a simple text value.
    /// If the value is nil, displays a dash placeholder.
    public init(_ title: String, value: String?) {
        self.init(title) {
            Text(value ?? "–")
                .foregroundColor(AppColor.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Text Value") {
    VStack(spacing: 16) {
        InfoRow("Email", value: "user@example.com")
        InfoRow("Country", value: "United States")
        InfoRow("Phone", value: nil)
    }
    .padding()
}

#Preview("Custom Content") {
    VStack(spacing: 16) {
        InfoRow("Status") {
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                Text("Active")
                    .foregroundStyle(.green)
            }
        }

        InfoRow("Website") {
            Link("example.com", destination: URL(string: "https://example.com")!)
        }

        InfoRow("Tags") {
            HStack(spacing: 4) {
                Text("Swift")
                Image(systemName: "chevron.forward")
                    .font(.caption2)
            }
            .foregroundStyle(.tint)
        }
    }
    .padding()
}

#Preview("In Card") {
    CardView("User Details") {
        VStack(spacing: 16) {
            InfoRow("Name", value: "John Appleseed")
            InfoRow("Email", value: "john@example.com")
            InfoRow("Member Since", value: "January 2024")
        }
    }
    .padding()
}
