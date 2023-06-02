import SwiftUI

struct DomainResultView: View {

    @State private var subtitleHeight: CGFloat = .zero
    let domain: String
    let dismiss: () -> Void

    private struct AttributedLabel: UIViewRepresentable {
        typealias UIViewType = UILabel
        @Binding var dynamicHeight: CGFloat

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
                dynamicHeight = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude)).height
            }
        }

        var configuration: (UIViewType) -> Void
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: Metrics.interItemVerticalPadding) {
                Image("Domains Lockup")
                    .padding(Metrics.logoPadding)
                    .accessibility(hidden: true)

                Text(TextContent.title)
                    .multilineTextAlignment(.leading)
                    .font(.largeTitle.bold())
                    .foregroundColor(Color.primary)

                AttributedLabel(dynamicHeight: $subtitleHeight) {
                    $0.attributedText = subtitleWith(domain: domain)
                }
                .foregroundColor(Color(UIColor.muriel(color: .text)))
                .frame(height: subtitleHeight)

                HStack(spacing: Metrics.noticeBoxHorizontalSpacing) {
                    Image(uiImage: .gridicon(.infoOutline))
                        .foregroundColor(Color(UIColor.muriel(color: .gray)))
                        .accessibility(hidden: true)
                    Text(TextContent.notice)
                        .foregroundColor(Color(UIColor.muriel(color: .textSubtle)))
                }
                .padding(Metrics.noticeBoxInsets)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.tertiaryFill))
                .cornerRadius(Metrics.noticeBoxCornerRadius)
            }.padding(Metrics.screenPadding)

            VStack {
                Spacer()
                Button(action: dismiss) {
                    ShapeWithTextView(title: TextContent.primaryButtonTitle).largeRoundedRectangle()
                }
            }
            .padding(Metrics.screenPadding)

        }
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
                                                          value: "Done!",
                                                          comment: "Done button title on the domain purchase result screen. Closes the screen.")
    }

    private enum Metrics {
        static let screenPadding = 15.0
        static let interItemVerticalPadding = 20.0
        static let logoPadding = 10.0
        static let noticeBoxInsets = EdgeInsets(top: 15, leading: 10, bottom: 15, trailing: 10)
        static let noticeBoxCornerRadius = 10.0
        static let noticeBoxHorizontalSpacing = 15.0
        static let primaryButtonCornerRadius = 7.0
    }

    private enum Fonts {
        static let subtitleFont = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .regular)
        static let subtitleFontBold = WPStyleGuide.fontForTextStyle(.title2, fontWeight: .bold)
    }
}
