import SwiftUI

/// Prologue editor page contents
struct UnifiedPrologueEditorContentView: View {

    var body: some View {

        VStack {
            Spacer(minLength: Appearance.topSpacing)
            RoundRectangleView {
                HStack {
                    Text(Appearance.topElementTitle)
                        .font(Appearance.largeTextFont)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding()
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Appearance.internalSpacerMinHeight)
                .fixedSize(horizontal: false, vertical: true)
            RoundRectangleView(alignment: .top) {
                (Text(Appearance.middleElementTitle)
                    + Text(Appearance.middleElementTerminator)
                    .foregroundColor(.blue))
                    .lineLimit(.none)
                    .padding()
                HStack {
                    CircledIcon(size: Appearance.alignImageLeftIconSize,
                                xOffset: Appearance.alignImageLeftIconXOffset,
                                yOffset: Appearance.alignImageLeftIconYOffset,
                                iconType: .alignImageLeft,
                                backgroundColor: Color(UIColor.muriel(name: .purple, .shade50)))
                    Spacer()
                    CircledIcon(size: Appearance.plusIconSize,
                                xOffset: Appearance.plusIconXOffset,
                                yOffset: Appearance.plusIconYOffset,
                                iconType: .plus,
                                backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
                }
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Appearance.internalSpacerMinHeight)
                .fixedSize(horizontal: false, vertical: true)
            RoundRectangleView {
                HStack {
                    Image("page2Img1Sea")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ZStack(alignment: .bottomLeading) {
                        Image("page2Img2Trees")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        CircledIcon(size: Appearance.imageMultipleIconSize,
                                    xOffset: Appearance.imageMultipleIconXOffset,
                                    yOffset: Appearance.imageMultipleIconYOffset,
                                    iconType: .imageMultiple,
                                    backgroundColor: Color(UIColor.muriel(name: .pink, .shade40)))
                    }
                    Image("page2Img3Food")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .padding(.all, Appearance.imageGalleryPadding)
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Appearance.imageMultipleIconYOffset)
        }
    }
}

private extension UnifiedPrologueEditorContentView {

    enum Appearance {
        static let topElementTitle: LocalizedStringKey = "Getting Inspired"
        static let middleElementShortTitle: LocalizedStringKey = "I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my"
        static let middleElementTerminator = "|"
        static let largeTextFont = Font(WPStyleGuide.serifFontForTextStyle(.title2))
        static let normalTextFont = Font.subheadline
        /// - TODO: This needs to be updated with actual text
        static let middleElementLongTitle: LocalizedStringKey = "I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my"

        static var middleElementTitle: LocalizedStringKey {
            WPDeviceIdentification.isiPad() ? middleElementLongTitle : middleElementShortTitle
        }

        // Spacing
        static let internalSpacerMinHeight: CGFloat = 8.0
        static let imageGalleryPadding: CGFloat = 8.0
        static let editorTitlePadding: CGFloat = 8.0
        static let topSpacing: CGFloat = 60.0

        // Icons
        static let plusIconSize: CGFloat = 52.0
        static let plusIconXOffset = plusIconSize * 2 / 3
        static let plusIconYOffset = -plusIconSize * 2 / 3

        static let alignImageLeftIconSize: CGFloat = 40.0
        static let alignImageLeftIconXOffset = -alignImageLeftIconSize * 3 / 4
        static let alignImageLeftIconYOffset = alignImageLeftIconSize

        static let imageMultipleIconSize: CGFloat = 48.0
        static let imageMultipleIconXOffset = -imageMultipleIconSize / 2
        static let imageMultipleIconYOffset = imageMultipleIconSize / 2
    }
}
