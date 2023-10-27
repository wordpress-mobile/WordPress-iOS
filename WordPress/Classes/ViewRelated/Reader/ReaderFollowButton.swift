import SwiftUI

struct ReaderFollowButton: View {

    let isFollowing: Bool
    let isEnabled: Bool
    let size: ButtonSize
    let action: () -> Void

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
        let textColor: Color = isFollowing ? .secondary : Color(UIColor.invertedLabel)
        let backgroundColor: Color = isFollowing ? .clear : Color(UIColor.label)
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
