import SwiftUI

struct PostSettingsTruncatedArrayTextView: View {
    let values: [String]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            if values.count >= 4 {
                ItemView(tags: Array(tags.prefix(4)), remainingCount: tags.count - 4)
            }
            if values.count >= 3 {
                ItemView(tags: Array(tags.prefix(3)), remainingCount: tags.count - 3)
            }
            // Try showing 2 values
            if values.count >= 2 {
                ItemView(tags: Array(tags.prefix(2)), remainingCount: tags.count - 2)
            }
            // Show one
            ItemView(tags: Array(tags.prefix(1)), remainingCount: tags.count - 1)
        }
    }
}

private struct ItemView: View {
    let values: [String]
    let remainingCount: Int

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(values.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            if remainingCount > 0 {
                Text("(+\(remainingCount))")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
                    .tracking(-0.5)
            }
        }
    }
}
