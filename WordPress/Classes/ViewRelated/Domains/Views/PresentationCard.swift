import SwiftUI

/// A card with a title, a description and a button that can present a view
struct PresentationCard<Appearance: View>: View {
    var title: String
    var description: String
    var highlight: String
    @Binding var isShowingDestination: Bool

    private let titleFontSize: CGFloat = 28

    var appearance: () -> Appearance

    var body: some View {
        VStack {
            Text(title)
                .font(Font.system(size: titleFontSize,
                                  weight: .regular,
                                  design: .serif))
                .padding()
            (Text(description) +
             Text(highlight).bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PresentationButton(
                isShowingDestination: $isShowingDestination,
                appearance: appearance)
                .padding()
        }
    }
}
