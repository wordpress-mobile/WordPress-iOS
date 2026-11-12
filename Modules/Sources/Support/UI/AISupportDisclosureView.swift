import SwiftUI

/// The fixed "You're chatting with AI from WordPress.com Support." line shown at the top of an AI support chat.
///
/// Required by the EU AI Act (Art. 50), which asks for a label at the top of the chat saying both that it is AI and
/// who it acts for, everywhere in the world: a footer or a small notice isn't enough. The wording is written by the
/// app, never by the bot.
///
/// Host it outside the scrolling messages — a top safe area inset, or above the web view in the older chat — so it is
/// there before the first reply and stays put however long the conversation grows. It only applies while the AI is
/// answering: once a conversation is handed to a Happiness Engineer and becomes a ticket, the ticket view doesn't
/// show it.
public struct AISupportDisclosureView: View {

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            Text(Strings.disclosure)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                // No line limit: at the largest text sizes the line wraps rather than being cut off.
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                // The inset the composer at the other end of the conversation takes, so the two bars the
                // screen wears are the same depth.
                .padding(.vertical, 8)

            Divider()
        }
        // The same material as the bar below the conversation: this is chrome the screen wears, not something
        // said in the conversation.
        .background(.bar)
    }
}

private enum Strings {

    /// The organization the AI acts for, as the disclosure standard asks. WordPress.com provides the support behind
    /// both apps, so this reads the same in WordPress and in Jetpack, and it isn't translated.
    static let organizationName = "WordPress.com"

    static var disclosure: String {
        String.localizedStringWithFormat(disclosureFormat, organizationName)
    }

    static let disclosureFormat = NSLocalizedString(
        "support.aiDisclosure.message",
        value: "You're chatting with AI from %1$@ Support.",
        comment:
            "Fixed line at the top of the AI support chat telling the user they are chatting with AI. %1$@ is the name of the organization the AI acts for, such as WordPress.com."
    )
}

#Preview {
    VStack(spacing: 0) {
        AISupportDisclosureView()
        Spacer()
    }
}
