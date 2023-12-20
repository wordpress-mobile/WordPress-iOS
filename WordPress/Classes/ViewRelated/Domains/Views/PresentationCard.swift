import SwiftUI
import DesignSystem

/// A card with a title, a description and a button that can present a view
struct PresentationCard: View {
    let title: String
    let description: String
    let destinationTitle: String
    @Binding var isShowingDestination: Bool

    var body: some View {
        VStack(spacing: Length.Padding.medium) {
            VStack(spacing: Length.Padding.single) {
                VStack(spacing: -Length.Padding.large) {
                    DashboardDomainsCardSearchView()
                    Text(title)
                        .style(.heading4)
                        .foregroundColor(.DS.Foreground.primary)
                }

                Text(description)
                    .style(.bodyLarge(.regular))
                    .foregroundColor(.DS.Foreground.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Length.Padding.single)
            }

            VStack(spacing: Length.Padding.single) {
                DSButton(
                    title: title,
                    style: .init(
                        emphasis: .primary,
                        size: .large,
                        isJetpack: AppConfiguration.isJetpack
                    )) {
                        isShowingDestination = true
                    }
            }
        }
    }
}
