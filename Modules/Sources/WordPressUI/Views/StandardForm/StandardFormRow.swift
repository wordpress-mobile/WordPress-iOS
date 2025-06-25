import SwiftUI
import DesignSystem

/// A reusable info row component that displays a title and customizable content.
/// Commonly used within cards or forms to display editable fields.
public struct StandardFormRow<Content: View>: View {
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
                .foregroundStyle(AppColor.secondary)
                .lineLimit(1)
        }
    }
}
