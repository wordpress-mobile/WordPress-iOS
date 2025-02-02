import SwiftUI
import WordPressReader

struct ReaderFollowButton: View {

    let isFollowing: Bool
    let isEnabled: Bool
    let size: ButtonSize
    var color: ButtonColor = .init()
    var displaySetting: ReaderDisplaySettings?

    let action: () -> Void

    struct ButtonColor {
        let followedText: Color
        let followedBackground: Color
        let followedStroke: Color

        let unfollowedText: Color
        let unfollowedBackground: Color

        init(followedText: Color = .secondary,
             followedBackground: Color = .clear,
             followedStroke: Color = Color(.separator),
             unfollowedText: Color = Color(UIColor.invertedLabel),
             unfollowedBackground: Color = Color(.label)) {
            self.followedText = followedText
            self.followedBackground = followedBackground
            self.followedStroke = followedStroke
            self.unfollowedText = unfollowedText
            self.unfollowedBackground = unfollowedBackground
        }

        init(displaySetting: ReaderDisplaySettings) {
            followedText = Color(displaySetting.color.secondaryForeground)
            followedBackground = .clear
            followedStroke = followedText
            unfollowedText = Color(displaySetting.color.background)
            unfollowedBackground = Color(displaySetting.color.foreground)
        }
    }

    enum ButtonSize {
        case compact
        case regular
    }

    init(isFollowing: Bool,
         isEnabled: Bool,
         size: ButtonSize,
         color: ButtonColor? = nil,
         displaySetting: ReaderDisplaySettings? = nil,
         action: @escaping () -> Void) {
        self.isFollowing = isFollowing
        self.isEnabled = isEnabled
        self.size = size
        self.color = color ?? {
            if let displaySetting {
                return .init(displaySetting: displaySetting)
            }
            return .init()
        }()
        self.displaySetting = displaySetting
        self.action = action
    }

    var body: some View {
        if isFollowing {
            button.overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color.followedStroke, lineWidth: 1)
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
                .font(buttonFont)
        }
        .disabled(!isEnabled)
        .padding(.horizontal, size == .compact ? 16.0 : 24.0)
        .padding(.vertical, 8.0)
        .background(backgroundColor)
        .cornerRadius(5.0)
    }

    var buttonFont: Font {
        guard let displaySetting else {
            return .subheadline
        }
        return Font(displaySetting.font(with: .subheadline))
    }
}
