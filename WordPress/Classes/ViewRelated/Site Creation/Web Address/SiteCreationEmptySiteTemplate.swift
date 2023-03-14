import SwiftUI

struct SiteCreationEmptySiteTemplate: View {
    private enum Constants {
        static let innerCornerRadius: CGFloat = 8
        static let containerCornerRadius: CGFloat = 16
        static let containerStackSpacing: CGFloat = 0
        static let siteBarHeight: CGFloat = 38
        static let siteBarStackSpacing: CGFloat = 8
        static let iconScaleFactor = 0.85
        static let backgroundColor = Color(red: 116/255, green: 116/255, blue: 128/255, opacity: 0.15)
        static let tooltipTextBackgroundColor = Color(red: 242/255, green: 241/255, blue: 246/255)
        static let innerRectangleBackgroundColor = Color.white.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: Constants.containerStackSpacing) {
            siteBarVStack
            tooltip
        }
        .background(
            LinearGradient(
                gradient: Gradient(
                    colors: [Constants.backgroundColor, Constants.innerRectangleBackgroundColor]
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
                .fill(Constants.innerRectangleBackgroundColor)
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
                    .foregroundColor(.secondary)
                Text(Strings.searchBarSiteAddress)
                    .font(.caption)
                    .accentColor(Color.primary)
                Spacer()
            }
            .padding([.leading, .trailing], Constants.siteBarStackSpacing)
        }
        .frame(height: Constants.siteBarHeight)
        .background(Color.white)
        .cornerRadius(Constants.innerCornerRadius)
    }

    private var plusView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Constants.innerCornerRadius)
                .fill(Color.white)
                .frame(width: Constants.siteBarHeight, height: Constants.siteBarHeight)
            Image(systemName: "plus")
                .scaleEffect(x: Constants.iconScaleFactor, y: Constants.iconScaleFactor)
                .foregroundColor(.secondary)
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
                        .background(Constants.tooltipTextBackgroundColor)
                        .cornerRadius(5)
                        Spacer()
                    }
                    Text(Strings.tooltipDescription)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            .padding(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        }
        .overlay( /// apply a rounded border
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .background(Color.white)
    }
}

private extension SiteCreationEmptySiteTemplate {
    enum Strings {
        static let tooltipSiteName = NSLocalizedString(
            "YourSiteName.com",
            comment: "Site name that is placed in the tooltip view."
        )

        static let tooltipDescription = NSLocalizedString(
            "Like the example above, a domain allows people to find and visit your site from their web browser.",
            comment: "Site name description that sits in the template website view."
        )

        static let searchBarSiteAddress = NSLocalizedString(
            "https://yoursitename.com",
            comment: "Template site address for the search bar."
        )
    }
}
