import SwiftUI

/// Prologue editor page contents
struct UnifiedPrologueEditorContentView: View {

    var body: some View {
        GeometryReader { content in

            VStack {
                Spacer(minLength: content.size.height * 0.18)

                RoundRectangleView {
                    HStack {
                        Text(Appearance.topElementTitle)
                            .font(Font.system(size: content.size.height * 0.08,
                                              weight: .semibold,
                                              design: .serif))
                        Spacer()
                    }
                    .padding(.all, content.size.height * 0.06)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: content.size.height * 0.03)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView(alignment: .top) {
                    (Text(Appearance.middleElementTitle)
                        + Text(Appearance.middleElementTerminator)
                        .foregroundColor(.blue))
                        .font(Font.system(size: content.size.height * 0.06,
                                          weight: .regular,
                                          design: .default))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(.none)
                        .padding(.all, content.size.height * 0.06)

                    HStack {
                        let alignImageLeftIconSize = content.size.height * 0.15
                        CircledIcon(size: alignImageLeftIconSize,
                                    xOffset: -alignImageLeftIconSize * 0.75,
                                    yOffset: alignImageLeftIconSize  * 0.75,
                                    iconType: .alignImageLeft,
                                    backgroundColor: Color(UIColor.muriel(name: .purple, .shade50)))

                        Spacer()

                        let plusIconSize = content.size.height * 0.2
                        CircledIcon(size: plusIconSize,
                                    xOffset: plusIconSize * 0.66,
                                    yOffset: -plusIconSize * 0.66,
                                    iconType: .plus,
                                    backgroundColor: Color(UIColor.muriel(name: .blue, .shade50)))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: content.size.height * 0.03)
                    .fixedSize(horizontal: false, vertical: true)

                RoundRectangleView {
                    HStack(spacing: content.size.height * 0.03) {
                        Image("page2Img1Sea")
                            .resizable()
                            .aspectRatio(contentMode: .fit)

                        ZStack(alignment: .bottomLeading) {
                            Image("page2Img2Trees")
                                .resizable()
                                .aspectRatio(contentMode: .fit)

                            let imageMultipleIconSize = content.size.height * 0.18
                            CircledIcon(size: imageMultipleIconSize,
                                        xOffset: -imageMultipleIconSize / 2,
                                        yOffset: imageMultipleIconSize / 2,
                                        iconType: .imageMultiple,
                                        backgroundColor: Color(UIColor.muriel(name: .pink, .shade40)))
                        }

                        Image("page2Img3Food")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .padding(.all, content.size.height * 0.03)
                }
                .fixedSize(horizontal: false, vertical: true)

                // avoid bottom overlapping due to the icon offset
                Spacer(minLength: content.size.height * 0.1)
            }
        }
    }
}

private extension UnifiedPrologueEditorContentView {

    enum Appearance {
        static let topElementTitle: LocalizedStringKey = "Getting Inspired"
        static let middleElementTitle: LocalizedStringKey = "I am so inspired by photographer Cameron Karsten's work. I will be trying these techniques on my next"
        static let middleElementTerminator = "|"
    }
}
