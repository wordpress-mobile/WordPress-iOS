import SwiftUI

struct StatsCardTitleView: View {
    let title: String
    let showChevron: Bool

    init(title: String, showChevron: Bool = false) {
        self.title = title
        self.showChevron = showChevron
    }

    var body: some View {
        HStack(alignment: .center) {
            content
        }
        .tint(Color.primary)
        .lineLimit(1)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    @ViewBuilder
    private var content: some View {
        let title = Text(title)
            .font(.headline)
            .foregroundColor(.primary)
        if showChevron {
            // Note: had to do that to fix the animation issuse with Menu
            // hiding the image.
            title + Text(" ") + Text(Image(systemName: "chevron.up.chevron.down"))
                .font(.caption2.weight(.semibold))
                .foregroundColor(.secondary)
                .baselineOffset(1)
        } else {
            title
        }
    }
}

struct InlineValuePickerTitle: View {
    let title: String

    init(title: String) {
        self.title = title
    }

    var body: some View {
        HStack(alignment: .center) {
            content
        }
        .tint(Color.primary)
        .lineLimit(1)
    }

    @ViewBuilder
    private var content: some View {
        let title = Text(title)
            .font(.subheadline)
            .fontWeight(.medium)

        // Note: had to do that to fix the animation issuse with Menu
        // hiding the image.
        title + Text(" ") + Text(Image(systemName: "chevron.up.chevron.down"))
            .font(.caption2.weight(.semibold))
            .foregroundColor(.secondary)
            .baselineOffset(1)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatsCardTitleView(title: "Posts & Pages", showChevron: true)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)

        StatsCardTitleView(title: "Referrers", showChevron: false)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
