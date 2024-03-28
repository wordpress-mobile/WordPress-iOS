import SwiftUI

struct ReaderFollowButton: View {

    let isFollowing: Bool
    let isEnabled: Bool
    let size: ButtonSize
    @State var color: ButtonColor = .init()

    let action: () -> Void

    struct ButtonColor {
        let followedText: Color
        let followedBackground: Color

        let unfollowedText: Color
        let unfollowedBackground: Color

        init(followedText: Color = .secondary,
             followedBackground: Color = .clear,
             unfollowedText: Color = Color(UIColor.invertedLabel),
             unfollowedBackground: Color = Color(.label)) {
            self.followedText = followedText
            self.followedBackground = followedBackground
            self.unfollowedText = unfollowedText
            self.unfollowedBackground = unfollowedBackground
        }
    }

    enum ButtonSize {
        case compact
        case regular
    }

    var body: some View {
        if isFollowing {
            button.overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        } else {
            button
        }
    }

    private var button: some View {
        let text = isFollowing ? WPStyleGuide.FollowButton.Text.followingStringForDisplay : WPStyleGuide.FollowButton.Text.followStringForDisplay
        let textColor: Color = isFollowing ? color.followedText : color.unfollowedText
        let backgroundColor: Color = isFollowing ? color.followedBackground : color.unfollowedBackground
        return Button {
            action()
        } label: {
            Text(text)
                .foregroundColor(textColor)
                .font(.subheadline)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, size == .compact ? 16.0 : 24.0)
        .padding(.vertical, 8.0)
        .background(backgroundColor)
        .cornerRadius(5.0)
    }
}
