import SwiftUI
import DesignSystem

class DomainPurchaseChoicesViewModel: ObservableObject {
    @Published var isGetDomainLoading: Bool = false
}

struct DomainPurchaseChoicesView: View {
    private enum Constants {
        static let imageLength: CGFloat = 36
    }

    @StateObject var viewModel = DomainPurchaseChoicesViewModel()

    let analyticsSource: String?

    let buyDomainAction: (() -> Void)
    let chooseSiteAction: (() -> Void)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .DS.Padding.single) {
                Text(Strings.header)
                    .font(.system(.largeTitle, design: .serif).weight(.medium))
                Text(Strings.subheader)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .padding(.bottom, .DS.Padding.medium)
                getDomainCard
                    .padding(.bottom, .DS.Padding.medium)
                chooseSiteCard
                    .padding(.bottom, .DS.Padding.single)
                Text(Strings.footnote)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.top, .DS.Padding.double)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .DS.Padding.double)
        .background(Color.DS.Background.primary)
        .onAppear {
            self.track(.purchaseDomainScreenShown)
        }
    }

    private var getDomainCard: some View {
        card(
            imageName: "site-menu-domains",
            title: Strings.buyDomainTitle,
            subtitle: Strings.buyDomainSubtitle,
            buttonTitle: Strings.buyDomainButtonTitle,
            isProgressViewActive: true
        ) {
            self.track(.purchaseDomainGetDomainTapped)
            self.buyDomainAction()
        }
    }

    private var chooseSiteCard: some View {
        card(
            imageName: "block-layout",
            title: Strings.chooseSiteTitle,
            subtitle: Strings.chooseSiteSubtitle,
            buttonTitle: Strings.chooseSiteButtonTitle,
            footer: Strings.chooseSiteFooter,
            isProgressViewActive: false
        ) {
            self.track(.purchaseDomainChooseSiteTapped)
            self.chooseSiteAction()
        }
    }

    private func card(
        imageName: String,
        title: String,
        subtitle: String,
        buttonTitle: String,
        footer: String? = nil,
        isProgressViewActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: .DS.Padding.single) {
            Group {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.DS.Background.brand(isJetpack: AppConfiguration.isJetpack))
                    .frame(width: Constants.imageLength, height: Constants.imageLength)
                    .padding(.top, .DS.Padding.double)
                VStack(alignment: .leading, spacing: .DS.Padding.single) {
                    Text(title)
                        .font(.title2.weight(.medium))
                    Text(subtitle)
                        .foregroundStyle(Color.DS.Foreground.secondary)
                    if let footer {
                        Text(footer)
                            .foregroundStyle(Color.DS.Foreground.brand(isJetpack: AppConfiguration.isJetpack))
                            .font(.body.bold())
                    }
                }
                .padding(.bottom, .DS.Padding.single)
                DSButton(
                    title: buttonTitle,
                    style: .init(emphasis: .primary, size: .large, isJetpack: AppConfiguration.isJetpack),
                    isLoading: isProgressViewActive ? $viewModel.isGetDomainLoading : .constant(false),
                    action: action
                )
                .padding(.bottom, .DS.Padding.double)
                .disabled(viewModel.isGetDomainLoading)
            }
            .padding(.horizontal, .DS.Padding.double)
        }
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chooseSiteTexts: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.single) {
            Text(Strings.chooseSiteTitle)
                .font(.title2.bold())
            Text(Strings.chooseSiteSubtitle)
                .foregroundStyle(Color.DS.Foreground.secondary)
            Text(Strings.chooseSiteFooter)
                .foregroundStyle(Color.DS.Foreground.brand(isJetpack: AppConfiguration.isJetpack))
        }
    }

    private func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]? = nil) {
        let defaultProperties: [AnyHashable: Any] = {
            guard let source = self.analyticsSource else {
                return [:]
            }
            return [WPAppAnalyticsKeySource: source]
        }()

        let properties = defaultProperties.merging(properties ?? [:]) { first, second in
            return first
        }

        WPAnalytics.track(event, properties: properties)
    }
}

private extension DomainPurchaseChoicesView {
    enum Strings {
        static let header = NSLocalizedString(
            "domain.management.purchase.title",
            value: "Choose how to use your domain",
            comment: "Domain management purchase domain screen title."
        )
        static let subheader = NSLocalizedString(
            "domain.management.purchase.subtitle",
            value: "Don't worry, you can easily add a site later.",
            comment: "Domain management purchase domain screen title"
        )

        static let buyDomainTitle = NSLocalizedString(
            "domain.management.buy.card.title",
            value: "Just buy a domain",
            comment: "Domain management buy domain card title"
        )

        static let buyDomainSubtitle = NSLocalizedString(
            "domain.management.buy.card.subtitle",
            value: "Add a site later.",
            comment: "Domain management buy domain card subtitle"
        )

        static let buyDomainButtonTitle = NSLocalizedString(
            "domain.management.buy.card.button.title",
            value: "Get Domain",
            comment: "Domain management buy domain card button title"
        )

        static let chooseSiteTitle = NSLocalizedString(
            "domain.management.site.card.title",
            value: "Existing WordPress.com site",
            comment: "Domain management choose site card title"
        )

        static let chooseSiteSubtitle = NSLocalizedString(
            "domain.management.site.card.subtitle",
            value: "Use with a site you already started.",
            comment: "Domain management choose site card subtitle"
        )

        static let chooseSiteFooter = NSLocalizedString(
            "domain.management.site.card.footer",
            value: "Free domain for the first year*",
            comment: "Domain management choose site card subtitle"
        )

        static let chooseSiteButtonTitle = NSLocalizedString(
            "domain.management.site.card.button.title",
            value: "Choose Site",
            comment: "Domain management choose site card button title"
        )

        static let footnote = NSLocalizedString(
            "domain.management.purchase.footer",
            value: "*A free domain for one year is included with all paid annual plans",
            comment: "Domain management choose site card button title"
        )
    }
}

struct DomainPurchaseChoicesView_Previews: PreviewProvider {
    static var previews: some View {
        DomainPurchaseChoicesView(viewModel: DomainPurchaseChoicesViewModel(), analyticsSource: nil) {
            print("Buy domain tapped.")
        } chooseSiteAction: {
            print("Choose site tapped")
        }
        .environment(\.colorScheme, .dark)
    }
}
