import UIKit
import SwiftUI


class UnifiedPrologueEditorContainerView: UIView {

    init() {
        super.init(frame: .zero)
        let controller = UIHostingController(rootView: UnifiedPrologueEditorView())
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
        addSubview(controller.view)
        pinSubviewToAllEdges(controller.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct UnifiedPrologueEditorView: View {

    var body: some View {

        VStack {
            Spacer()
            RoundRectangleView {
                Text(Appearance.topElementTitle)
                    .font(Appearance.largeTextFont)
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
                .fixedSize(horizontal: false, vertical: true)
            RoundRectangleView {
                (Text(Appearance.middleElementTitle)
                    + Text(Appearance.middleElementTerminator)
                    .foregroundColor(.blue))
                    .lineLimit(.none)
                    .padding()
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 16)
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
                .padding(.all, 8)
            }

            .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
}

private extension UnifiedPrologueEditorView {

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
    }
}
