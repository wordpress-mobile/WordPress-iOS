import SwiftUI

/// Prologue editor page contents
struct UnifiedPrologueEditorContentView: View {

    var body: some View {

        VStack {
            Spacer()
            RoundRectangleView {
                Text(Appearance.topElementTitle)
                    .font(Appearance.largeTextFont)
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Appearance.internalSpacerMinHeight)
                .fixedSize(horizontal: false, vertical: true)
            RoundRectangleView {
                (Text(Appearance.middleElementTitle)
                    + Text(Appearance.middleElementTerminator)
                    .foregroundColor(.blue))
                    .lineLimit(.none)
                    .padding()
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Appearance.internalSpacerMinHeight)
                .fixedSize(horizontal: false, vertical: true)
            RoundRectangleView {
                HStack {
                    Image("page2Img1Sea")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image("page2Img2Trees")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image("page2Img3Food")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding(.all, Appearance.imageGalleryPadding)
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

private extension UnifiedPrologueEditorContentView {

    enum Appearance {
        static let topElementTitle: LocalizedStringKey = "Getting Inspired"
        static let middleElementShortTitle: LocalizedStringKey = "I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my"
        static let middleElementTerminator = "|"
        static let largeTextFont = Font(WPStyleGuide.serifFontForTextStyle(.title1))
        static let normalTextFont = Font.subheadline
        /// - TODO: This needs to be updated with actual text
        static let middleElementLongTitle: LocalizedStringKey = "I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my"

        static var middleElementTitle: LocalizedStringKey {
            WPDeviceIdentification.isiPad() ? middleElementLongTitle : middleElementShortTitle
        }

        static let internalSpacerMinHeight: CGFloat = 16.0
        static let imageGalleryPadding: CGFloat = 8.0
    }
}
