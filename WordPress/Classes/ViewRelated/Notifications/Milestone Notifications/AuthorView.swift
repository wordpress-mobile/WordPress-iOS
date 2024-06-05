import SwiftUI
import DesignSystem

struct AuthorView: View {
    private enum Constants {
        static let avatarDiameter: CGFloat = 40
    }

    private let avatarURL: URL?
    private let title: String
    private let subtitle: String

    init(
        avatarURL: URL?,
        title: String,
        subtitle: String
    ) {
        self.avatarURL = avatarURL
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        HStack(spacing: .DS.Padding.single) {
            avatar
            textsVStack
            Spacer()
            // Out of scope for current implementation.
//            contextButton
        }
    }

    private var avatar: some View {
        CachedAsyncImage(url: avatarURL)
            .frame(
                width: Constants.avatarDiameter,
                height: Constants.avatarDiameter
            )
            .clipShape(Circle())
    }

    private var textsVStack: some View {
        VStack(alignment: .leading) {
            Text(title)
                .style(.bodyLarge(.regular))
                .foregroundStyle(Color.DS.Foreground.primary)
                .lineLimit(1)
            Text(subtitle)
                .style(.bodySmall(.regular))
                .foregroundStyle(Color.DS.Foreground.secondary)
                .lineLimit(1)
        }
    }

    private var contextButton: some View {
        Button(action: {
            // TODO: Out of scope for current iteration.
        }, label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Color.DS.Foreground.secondary)
        })
    }
}

#Preview {
    AuthorView(
        avatarURL: URL(string: "https://picsum.photos/40/40")!,
        title: "Endurance: Expedition to South Pole",
        subtitle: "ernestshackleton.com"
    )
}
