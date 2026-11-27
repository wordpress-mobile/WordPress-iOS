import DesignSystem
import SwiftUI

struct ConversationBotIntro: View {
    let currentUser: SupportUser

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "sparkles")
                .font(.largeTitle.weight(.medium))
                .foregroundStyle(AppColor.primary)

            VStack(alignment: .leading, spacing: 16) {
                // Greeting with wave emoji
                HStack {
                    Text(String.localizedStringWithFormat(Localization.botGreeting, currentUser.username))
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(verbatim: "👋")
                        .font(.title2)
                }

                // Description text
                Text(Localization.botIntroduction)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
                    .textSelection(.enabled)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ConversationBotIntro(currentUser: SupportDataProvider.supportUser)
        // Matches the inset the conversation gives its messages.
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
}
