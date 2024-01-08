import SwiftUI

struct DomainResultView: View {
    @State private var subtitleHeight: CGFloat = .zero
    let domain: String
    let dismiss: () -> Void

    private struct AttributedLabel: UIViewRepresentable {
        typealias UIViewType = UILabel
        var currentWidth: CGFloat
        @Binding var dynamicHeight: CGFloat
        var configuration: (UIViewType) -> Void

        func makeUIView(context: Context) -> UILabel {
            let label = UIViewType()
            label.numberOfLines = 0
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            label.lineBreakMode = .byWordWrapping
            return label
        }

        func updateUIView(_ uiView: UILabel, context: Context) {
            configuration(uiView)
            // Makes the label vertically hug its multi-line content
            DispatchQueue.main.async {
                dynamicHeight = uiView.sizeThatFits(CGSize(width: currentWidth, height: CGFloat.greatestFiniteMagnitude)).height
            }
        }
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading) {
                        Image("Domains Lockup")
                            .padding(Metrics.logoPadding)
                            .frame(height: Metrics.logoHeight)
                            .accessibility(hidden: true)

                        Spacer().frame(height: Metrics.logoToTitleSpacing)

                        Text(TextContent.title)
                            .multilineTextAlignment(.leading)
                            .font(.largeTitle.bold())
                            .foregroundColor(Color.primary)

                        Spacer().frame(height: Metrics.titleToSubtitleSpacing)

                        AttributedLabel(currentWidth: geometry.size.width, dynamicHeight: $subtitleHeight) {
                            $0.attributedText = subtitleWith(domain: domain)
                        }
                        .foregroundColor(Color(UIColor.muriel(color: .text)))
                        .frame(height: subtitleHeight)

                        Spacer().frame(height: Metrics.subtitleToNoticeBoxSpacing)

                        DomainSetupNoticeView(noticeText: TextContent.notice)
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
                }
            }

            Button(action: dismiss) {
                ShapeWithTextView(title: TextContent.primaryButtonTitle)
                    .largeRoundedRectangle()
                    .font(.headline)
            }
        }
        .padding(Metrics.screenPadding)
    }

    private func subtitleWith(domain: String) -> NSAttributedString {
        let templateString = String.localizedStringWithFormat(TextContent.subtitle, domain)
        let attributedString = NSMutableAttributedString(string: templateString, attributes: [.font: Fonts.subtitleFont])
        let range = (attributedString.string as NSString).localizedStandardRange(of: domain)
        attributedString.setAttributes([.font: Fonts.subtitleFontBold], range: range)
        return attributedString
    }
}

// MARK: - Constants
private extension DomainResultView {

    private enum TextContent {
        static let title = NSLocalizedString("freeToPaidPlans.resultView.title",
                                             value: "All ready to go!",
                                             comment: "Title for the domain purchase result screen. Tells user their domain was obtained.")
        static let subtitle = NSLocalizedString("freeToPaidPlans.resultView.subtitle",
                                                value: "Your new domain %@ is being set up.",
                                                comment: "Sub-title for the domain purchase result screen. Tells user their domain is being set up.")
        static let notice = NSLocalizedString("freeToPaidPlans.resultView.notice",
                                              value: "It may take up to 30 minutes for your domain to start working properly",
                                              comment: "Notice on the domain purchase result screen. Tells user how long it might take for their domain to be ready.")
        static let primaryButtonTitle = NSLocalizedString("freeToPaidPlans.resultView.done",
                                                          value: "Done",
                                                          comment: "Done button title on the domain purchase result screen. Closes the screen.")
    }

    private enum Metrics {
        static let screenPadding = 16.0
        static let logoPadding = 10.0
        static let logoHeight = 65.0
        static let logoToTitleSpacing = 33.0
        static let titleToSubtitleSpacing = 16.0
        static let subtitleToNoticeBoxSpacing = 32.0
    }

    private enum Fonts {
        static let subtitleFont = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .regular)
        static let subtitleFontBold = WPStyleGuide.fontForTextStyle(.title3, fontWeight: .bold)
    }
}
