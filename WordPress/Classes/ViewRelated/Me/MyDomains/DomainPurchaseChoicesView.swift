import SwiftUI

struct DomainPurchaseChoicesView: View {
    private enum Constants {
        static let imageLength: CGFloat = 36
    }

    let buyDomainAction: (() -> Void)
    let chooseSiteAction: (() -> Void)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Length.Padding.double) {
                Text(Strings.header)
                    .font(.largeTitle.bold())
                Text(Strings.subheader)
                    .font(.body)
                getDomainCard
                chooseSiteCard
                Text(Strings.footnote)
                    .foregroundStyle(Color.DS.Foreground.secondary)
                    .font(.subheadline)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Length.Padding.double)
        .background(Color.DS.Background.secondary)
    }

    private var getDomainCard: some View {
        card(imageName: "site-menu-domains",
             title: Strings.buyDomainTitle,
             subtitle: Strings.buyDomainSubtitle,
             buttonTitle: Strings.buyDomainButtonTitle,
             action: buyDomainAction)
    }

    private var chooseSiteCard: some View {
        card(imageName: "block-layout",
             title: Strings.chooseSiteTitle,
             subtitle: Strings.chooseSiteSubtitle,
             buttonTitle: Strings.chooseSiteButtonTitle,
             footer: Strings.chooseSiteFooter,
             action: chooseSiteAction
        )
    }

    private func card(
        imageName: String,
        title: String,
        subtitle: String,
        buttonTitle: String,
        footer: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            Group {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(Color.DS.Background.brand)
                    .frame(width: Constants.imageLength, height: Constants.imageLength)
                    .padding(.top, Length.Padding.double)
                VStack(alignment: .leading, spacing: Length.Padding.single) {
                    Text(title)
                        .font(.title2.bold())
                    Text(subtitle)
                        .foregroundStyle(Color.DS.Foreground.secondary)
                    if let footer {
                        Text(footer)
                            .foregroundStyle(Color.DS.Foreground.brand)
                    }
                }
                .padding(.bottom, Length.Padding.single)
                PrimaryButton(title: buttonTitle) {
                    action()
                }
                .padding(.bottom, Length.Padding.double)
            }
            .padding(.horizontal, Length.Padding.double)
        }
        .background(Color.DS.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chooseSiteTexts: some View {
        VStack(alignment: .leading, spacing: Length.Padding.single) {
            Text(Strings.chooseSiteTitle)
                .font(.title2.bold())
            Text(Strings.chooseSiteSubtitle)
                .foregroundStyle(Color.DS.Foreground.secondary)
            Text(Strings.chooseSiteFooter)
                .foregroundStyle(Color.DS.Foreground.brand)
        }
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
            comment: "Doman management buy domain card title"
        )

        static let buyDomainSubtitle = NSLocalizedString(
            "domain.management.buy.card.subtitle",
            value: "Add a site later",
            comment: "Doman management buy domain card subtitle"
        )

        static let buyDomainButtonTitle = NSLocalizedString(
            "domain.management.buy.card.button.title",
            value: "Get Domain",
            comment: "Doman management buy domain card button title"
        )

        static let chooseSiteTitle = NSLocalizedString(
            "domain.management.site.card.title",
            value: "Existing WordPress.com site",
            comment: "Doman management choose site card title"
        )

        static let chooseSiteSubtitle = NSLocalizedString(
            "domain.management.site.card.subtitle",
            value: "Use with a site you already started.",
            comment: "Doman management choose site card subtitle"
        )

        static let chooseSiteFooter = NSLocalizedString(
            "domain.management.site.card.footer",
            value: "Free domain for the first year*",
            comment: "Doman management choose site card subtitle"
        )

        static let chooseSiteButtonTitle = NSLocalizedString(
            "domain.management.site.card.button.title",
            value: "Choose Site",
            comment: "Doman management choose site card button title"
        )

        static let footnote = NSLocalizedString(
            "domain.management.purchase.footer",
            value: "*A free domain for one year is included with all paid annual plans",
            comment: "Doman management choose site card button title"
        )
    }
}

struct DomainPurchaseChoicesView_Previews: PreviewProvider {
    static var previews: some View {
        DomainPurchaseChoicesView {
            print("Buy domain tapped.")
        } chooseSiteAction: {
            print("Choose site tapped")
        }
    }
}
