import SwiftUI

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
        VStack(spacing: Constants.containerStackSpacing) {
            siteBarVStack
            tooltip
        }
        .background(
            LinearGradient(
                gradient: Gradient(
                    colors: [Color.emptySiteGradientInitial, Color.DS.Background.primary]
                ),
                startPoint: .top,
                endPoint: .center
            )
        )
        .cornerRadius(Constants.containerCornerRadius)
    }

    private var siteBarVStack: some View {
        VStack(spacing: Constants.siteBarStackSpacing) {
            siteBarHStack
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [Color.emptySiteTooltipGradientInitial, Color.DS.Background.primary]
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
                    .foregroundColor(Color.DS.Foreground.secondary)
                Text(Strings.searchBarSiteAddress)
                    .font(.caption)
                    .accentColor(Color.DS.Foreground.primary)
                Spacer()
            }
            .padding([.leading, .trailing], Constants.siteBarStackSpacing)
        }
        .frame(height: Constants.siteBarHeight)
        .background(Color.DS.Background.primary)
        .cornerRadius(Constants.innerCornerRadius)
    }

    private var plusView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.innerCornerRadius)
                .fill(Color.DS.Background.primary)
                .frame(width: Constants.siteBarHeight, height: Constants.siteBarHeight)
            Image(systemName: "plus")
                .scaleEffect(x: Constants.iconScaleFactor, y: Constants.iconScaleFactor)
                .foregroundColor(Color.DS.Foreground.secondary)
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
                        .background(Color.DS.Background.secondary)
                        .cornerRadius(5)
                        Spacer()
                    }
                    Text(Strings.tooltipDescription)
                        .font(.footnote)
                        .foregroundColor(Color.DS.Foreground.secondary)
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
    static let emptySiteGradientInitial = Color("emptySiteGradientInitial")
    static let emptySiteTooltipGradientInitial = Color("emptySiteTooltipGradientInitial")
    static let emptySiteTooltipBackground = Color("emptySiteTooltipBackground")
    static let emptySiteTooltipBorder = Color("emptySiteTooltipBorder")
}
