import SwiftUI

/// A reusable view component that displays a title and subtitle in a list item format.
public struct SubtitledListViewItem: View {
    private let title: String
    private let subtitle: String

    /// Initialize a new SubtitledListViewItem
    /// - Parameters:
    ///   - title: The main text to display
    ///   - subtitle: The secondary text to display below the title
    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        SubtitledListViewItem(
            title: "Example Title",
            subtitle: "This is a longer subtitle that might wrap to a second line depending on the available width"
        )

        SubtitledListViewItem(
            title: "Another Item",
            subtitle: "Brief description"
        )
    }
}
