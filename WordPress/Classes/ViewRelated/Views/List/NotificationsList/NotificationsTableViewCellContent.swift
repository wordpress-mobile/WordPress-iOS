import SwiftUI
import DesignSystem

extension NotificationsTableViewCell {
    struct Content: View {
        let title: String
        let description: String
        let shouldShowIndicator: Bool

        var body: some View {
            HStack(spacing: 0) {
                indicator
                    .padding(.horizontal, Length.Padding.half)
            }
        }

        private var indicator: some View {
            Circle()
                .frame(width: Length.Padding.single)
                .background(
                    Color.DS.Background.brand(
                        isJetpack: AppConfiguration.isJetpack
                    )
                )
        }
    }
}

#if DEBUG
#Preview {
    NotificationsTableViewCell.Content(
        title: "Something",
        description: "Description",
        shouldShowIndicator: true
    )
}
#endif
