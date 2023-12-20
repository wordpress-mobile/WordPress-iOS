import SwiftUI
import DesignSystem

/// A card with a title, a description and a button that can present a view
struct PresentationCard: View {
    let title: String
    let description: String
    let destinationTitle: String
    @Binding var isShowingDestination: Bool

    private let titleFontSize: CGFloat = 28

    var body: some View {
        VStack {
            Text(title)
                .font(Font.system(size: titleFontSize, weight: .regular, design: .serif))
                .padding()
            Text(description)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
