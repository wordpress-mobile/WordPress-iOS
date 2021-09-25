import SwiftUI

/// A card with a title, a description and a button that can present a view
struct PresentationCard<Destination: View, Appearance: View>: View {
    var title: String
    var description: String
    var highlight: String

    private let titleFontSize: CGFloat = 28

    var destination: () -> Destination
    var appearance: () -> Appearance

    var body: some View {
        VStack {
            Text(title)
                .font(Font.system(size: titleFontSize,
                                  weight: .regular,
                                  design: .serif))
                .padding()
            (Text(description) +
             Text(highlight).bold()).multilineTextAlignment(.center)
            PresentationButton(destination: destination, appearance: appearance)
                .padding()
        }
    }
}
