import SwiftUI

struct PostSettingsTruncatedArrayTextView: View {
    let values: [String]

    var body: some View {
        /// Show the longest version that fits up to four.
        /// Example: "Techology, Blogging (+3)"
        ViewThatFits(in: .horizontal) {
            if values.count >= 4 {
                ItemView(values: Array(values.prefix(4)), remainingCount: values.count - 4)
            }
            if values.count >= 3 {
                ItemView(values: Array(values.prefix(3)), remainingCount: values.count - 3)
            }
            if values.count >= 2 {
                ItemView(values: Array(values.prefix(2)), remainingCount: values.count - 2)
            }
            ItemView(values: Array(values.prefix(1)), remainingCount: values.count - 1)
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
            if remainingCount > 0 {
                Text("(+\(remainingCount))")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(.secondary)
                    .tracking(-0.5)
            }
        }
        .lineLimit(1)
    }
}
