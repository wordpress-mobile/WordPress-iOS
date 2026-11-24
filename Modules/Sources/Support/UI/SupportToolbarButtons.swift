import SwiftUI

/// A cancel button that follows the platform: the system's own glyph from iOS 26, the word before that.
///
/// The app has a shared version of this, but it lives next to the screens that use the app's navigation, which
/// already depends on this module.
struct SupportCancelButton: View {

    /// Shown before iOS 26, and read out in place of the glyph after it.
    let title: String

    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .cancel, action: action)
        } else {
            Button(title, action: action)
        }
    }
}

/// A send button, shown from iOS 26 as the same arrow the chat composer uses.
struct SupportSendButton: View {

    /// Shown before iOS 26, and read out in place of the arrow after it.
    let title: String

    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                Image(systemName: "arrow.up")
            }
            .accessibilityLabel(title)
        } else {
            Button(title, action: action)
        }
    }
}
