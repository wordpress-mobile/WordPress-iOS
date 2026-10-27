import DesignSystem
import SwiftUI

/// The status of a conversation, shown the way the app shows status everywhere else: a tinted symbol and label
/// rather than a filled badge. See `PostListCell`, which renders a post's status as a plain colored label.
struct UnifiedSupportStatusLabel: View {

    let status: UnifiedSupportConversationStatus

    var body: some View {
        Label(status.title, systemImage: status.symbol)
            .labelStyle(CompactLabelStyle())
            .font(.footnote)
            .foregroundStyle(status.tint)
            .accessibilityLabel(status.title)
    }
}

/// Keeps the icon snug against the text. The automatic style inside a `List` reserves a wide icon column, which
/// pushes the text away from the icon.
private struct CompactLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 5) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        UnifiedSupportStatusLabel(status: .bot)
        UnifiedSupportStatusLabel(status: .ongoing)
        UnifiedSupportStatusLabel(status: .solved)
        UnifiedSupportStatusLabel(status: .closed)
        UnifiedSupportStatusLabel(status: .unknown)
    }
}
