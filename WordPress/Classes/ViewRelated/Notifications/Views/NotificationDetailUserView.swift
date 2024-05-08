import SwiftUI
import DesignSystem

struct NotificationDetailUserView: View {
	typealias FollowConfig = NotificationDetailUserView.FollowActionConfiguration

    let config: Configuration

    init(avatarURL: URL?, username: String?, blog: String?, onUserClicked: @escaping () -> Void) {
        self.config = Configuration(avatarURL: avatarURL, username: username, blog: blog, onUserClicked: onUserClicked)
    }

    init(
        avatarURL: URL?,
        username: String?,
        blog: String?,
        isFollowed: Bool,
        onUserClicked: @escaping () -> Void,
        onFollowClicked: @escaping (Bool) -> Void
    ) {
        self.config = Configuration(
            avatarURL: avatarURL,
            username: username,
            blog: blog,
            followActionConfig: FollowConfig(isFollowed: isFollowed, onFollowClicked: onFollowClicked),
            onUserClicked: onUserClicked
        )
    }

    var body: some View {
        HStack {
            Button(action: config.onUserClicked) {
                HStack(spacing: .DS.Padding.split) {
                    AvatarsView(style: .single(config.avatarURL))
                    VStack(alignment: .leading) {
                        if let username = config.username {
                            Text(username)
                                .style(.bodySmall(.regular))
                                .foregroundStyle(Color.DS.Foreground.primary)
                                .lineLimit(1)
                        }
                        if let blog = config.blog {
                            Text(blog)
                                .style(.bodySmall(.regular))
                                .foregroundStyle(Color.DS.Foreground.secondary)
                                .lineLimit(1)
                        }
                    }
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
        Button(action: {
            isFollowed.toggle()
            onFollowClicked(isFollowed)
        }) {
            HStack(spacing: .DS.Padding.half) {
                if isFollowed {
                    Image.DS.icon(named: .readerFollowing)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color.DS.Foreground.success)
                    Text(Follow.selectedTitle)
                        .style(.bodySmall(.regular))
                        .accessibilityHint(Follow.selectedHint)
                        .foregroundStyle(Color.DS.Foreground.success)
                } else {
                    Image.DS.icon(named: .readerFollow)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(Color.DS.Foreground.secondary)
                    Text(Follow.title)
                        .style(.bodySmall(.regular))
                        .accessibilityHint(Follow.hint)
                        .foregroundStyle(Color.DS.Foreground.secondary)
                }
            }
        }
    }
}

public struct ImageConfiguration {
    let url: URL?
    let placeholder: Image?

    public init(url: URL?, placeholder: Image? = nil) {
        self.url = url
        self.placeholder = placeholder
    }

    public init(url: String?, placeholder: Image? = nil) {
        self.init(url: URL(string: url ?? ""), placeholder: placeholder)
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
