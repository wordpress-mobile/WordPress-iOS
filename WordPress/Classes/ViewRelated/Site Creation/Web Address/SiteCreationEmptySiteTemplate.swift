import SwiftUI
import DesignSystem

struct SiteCreationEmptySiteTemplate: View {
    private enum Constants {
        static let innerCornerRadius: CGFloat = 8
        static let containerCornerRadius: CGFloat = 16
        static let containerStackSpacing: CGFloat = 0
        static let siteBarHeight: CGFloat = 38
        static let siteBarStackSpacing: CGFloat = 8
        static let iconScaleFactor = 0.85
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: Constants.containerStackSpacing) {
                siteBarVStack
                tooltip
            }
            .background(
                LinearGradient(
                    gradient: Gradient(
                        colors: [Color.emptySiteGradientInitial, Color.emptySiteBackgroundPrimary]
                    ),
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .cornerRadius(Constants.containerCornerRadius)
            Spacer()
            Spacer()
        }

    }

    private var siteBarVStack: some View {
        VStack(spacing: Constants.siteBarStackSpacing) {
            siteBarHStack
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [Color.emptySiteTooltipGradientInitial, Color.emptySiteBackgroundPrimary]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 100)
                .cornerRadius(Constants.innerCornerRadius)
        }
        .padding(8)
    }

    private var siteBarHStack: some View {
        HStack(spacing: Constants.siteBarStackSpacing) {
            siteSearchFieldHStack
            plusView
        }
        .frame(height: Constants.siteBarHeight)
    }

    private var siteSearchFieldHStack: some View {
        ZStack {
            HStack(spacing: Constants.siteBarStackSpacing) {
                Image(systemName: "lock")
                    .scaleEffect(x: Constants.iconScaleFactor, y: Constants.iconScaleFactor)
                    .foregroundColor(Color.emptySiteForegroundSecondary)
                Text(Strings.searchBarSiteAddress)
                    .font(.caption)
                    .accentColor(Color.emptySiteForegroundPrimary)
                Spacer()
            }
            .padding([.leading, .trailing], Constants.siteBarStackSpacing)
        }
        .frame(height: Constants.siteBarHeight)
        .background(Color.emptySiteBackgroundPrimary)
        .cornerRadius(Constants.innerCornerRadius)
    }

    private var plusView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.innerCornerRadius)
                .fill(Color.emptySiteBackgroundPrimary)
                .frame(width: Constants.siteBarHeight, height: Constants.siteBarHeight)
            Image(systemName: "plus")
                .scaleEffect(x: Constants.iconScaleFactor, y: Constants.iconScaleFactor)
                .foregroundColor(Color.emptySiteForegroundSecondary)
        }
    }

    private var tooltip: some View {
        ZStack {
                VStack(spacing: Constants.siteBarStackSpacing) {
                    HStack {
                        HStack {
                            Text(Strings.tooltipSiteName)
                                .font(.caption)
                                .padding(5)
                        }
                        .background(Color.emptySiteBackgroundSecondary)
                        .cornerRadius(5)
                        Spacer()
                    }
                    Text(Strings.tooltipDescription)
                        .font(.footnote)
                        .foregroundColor(Color.emptySiteForegroundSecondary)
                }
            .padding(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        }
        .background(Color.emptySiteTooltipBackground)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.emptySiteTooltipBorder, lineWidth: 0.8)
        )
        .padding(.bottom, 8)
    }
}

private extension SiteCreationEmptySiteTemplate {
    enum Strings {
        static let tooltipSiteName = NSLocalizedString(
            "site.creation.domain.tooltip.site.name",
            value: "YourSiteName.com",
            comment: "Site name that is placed in the tooltip view."
        )

        static let tooltipDescription = NSLocalizedString(
            "site.creation.domain.tooltip.description",
            value: "Like the example above, a domain allows people to find and visit your site from their web browser.",
            comment: "Site name description that sits in the template website view."
        )

        static let searchBarSiteAddress = NSLocalizedString(
            "site.cration.domain.site.address",
            value: "https://yoursitename.com",
            comment: "Template site address for the search bar."
        )
    }
}

private extension Color {
    static let emptySiteBackgroundPrimary = Color.DS.custom("emptySiteBackgroundPrimary")
    static let emptySiteBackgroundSecondary = Color.DS.custom("emptySiteBackgroundSecondary")
    static let emptySiteForegroundPrimary = Color.DS.custom("emptySiteForegroundPrimary")
    static let emptySiteForegroundSecondary = Color.DS.custom("emptySiteForegroundSecondary")
    static let emptySiteGradientInitial = Color.DS.custom("emptySiteGradientInitial")
    static let emptySiteTooltipGradientInitial = Color.DS.custom("emptySiteTooltipGradientInitial")
    static let emptySiteTooltipBackground = Color.DS.custom("emptySiteTooltipBackground")
    static let emptySiteTooltipBorder = Color.DS.custom("emptySiteTooltipBorder")
}
