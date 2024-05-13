import SwiftUI
import DesignSystem

struct NotificationDetailUserView: View {
	typealias FollowConfig = NotificationDetailUserView.FollowActionConfiguration

    let config: Configuration

    init(
        avatarURL: URL?,
        username: String?,
        blog: String?,
        isFollowed: Bool? = nil,
        onUserClicked: @escaping () -> Void,
        onFollowClicked: @escaping (Bool) -> Void = { _ in }
    ) {
        self.config = Configuration(
            avatarURL: avatarURL,
            username: username,
            blog: blog,
            followActionConfig: isFollowed.map { FollowConfig(isFollowed: $0, onFollowClicked: onFollowClicked) },
            onUserClicked: onUserClicked
        )
    }

    var body: some View {
        HStack {
            Button(action: config.onUserClicked) {
                HStack(spacing: .DS.Padding.split) {
                    AvatarsView(style: .single(config.avatarURL))
                    userView
                    Spacer()
                }
            }
            if let followAction = config.followActionConfig {
                FollowButton(config: followAction)
            }
        }
        .padding(.horizontal, .DS.Padding.double)
        .padding(.top, .DS.Padding.double)
    }

    private var userView: some View {
        VStack(alignment: .leading) {
            if let username = config.username { userNameView(username) }
            if let blog = config.blog { blogNameView(blog) }
        }
    }

    private func userNameView(_ name: String) -> some View {
        Text(name)
            .style(.bodySmall(.regular))
            .foregroundStyle(Color.DS.Foreground.primary)
            .lineLimit(1)
    }

    private func blogNameView(_ blog: String) -> some View {
        Text(blog)
            .style(.bodySmall(.regular))
            .foregroundStyle(Color.DS.Foreground.secondary)
            .lineLimit(1)
    }

    struct Configuration {
        let avatarURL: URL?
        let username: String?
        let blog: String?
        let followActionConfig: FollowActionConfiguration?
        let onUserClicked: () -> Void

        init(
            avatarURL: URL?,
            username: String?,
            blog: String?,
            followActionConfig: FollowActionConfiguration? = nil,
            onUserClicked: @escaping () -> Void
        ) {
            self.avatarURL = avatarURL
            self.username = username
            self.blog = blog
            self.followActionConfig = followActionConfig
            self.onUserClicked = onUserClicked
        }
    }

    struct FollowActionConfiguration {
        let isFollowed: Bool
        let onFollowClicked: (Bool) -> Void
    }

}

private struct FollowButton: View {
    @State private var isFollowed: Bool
    let onFollowClicked: (Bool) -> Void

    init(config: NotificationDetailUserView.FollowActionConfiguration) {
        self._isFollowed = State(initialValue: config.isFollowed)
        self.onFollowClicked = config.onFollowClicked
    }

    var body: some View {
        DSButton(
            title: isFollowed ? Follow.selectedTitle : Follow.title,
            style: .init(emphasis: isFollowed ? .secondary : .primary, size: .small)
        ) {
            isFollowed.toggle()
            onFollowClicked(isFollowed)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        NotificationDetailUserView(
            avatarURL: URL(string: "https://i.pravatar.cc/300"),
            username: "Alex Turner",
            blog: "@alexturner",
            isFollowed: false,
            onUserClicked: {},
            onFollowClicked: { _ in }
        )
        NotificationDetailUserView(
            avatarURL: URL(string: "invalid-url"),
            username: "Jordan Fisher",
            blog: "@jordanfisher",
            onUserClicked: {}
        )
        NotificationDetailUserView(
            avatarURL: URL(string: "https://i.pravatar.cc/400"),
            username: "Casey Hart",
            blog: nil,
            onUserClicked: {}
        )
        NotificationDetailUserView(
            avatarURL: URL(string: "https://i.pravatar.cc/600"),
            username: nil,
            blog: "@emilystanton",
            onUserClicked: {}
        )
    }
    .padding(.horizontal, .DS.Padding.double)
}
