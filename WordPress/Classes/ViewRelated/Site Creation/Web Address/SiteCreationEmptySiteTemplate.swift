import SwiftUI

struct SiteCreationEmptySiteTemplate: View {
    private enum Constants {
        static let innerCornerRadius: CGFloat = 8
        static let containerCornerRadius: CGFloat = 16
        static let containerStackSpacing: CGFloat = 16
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
                endPoint: .bottom
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
                Text("https://yoursitename.com")
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
            HStack {
                VStack(spacing: Constants.siteBarStackSpacing) {
                    Text("YourSiteName.com")
                        .font(.caption)
                        .background(Constants.tooltipTextBackgroundColor)
                    Text("Like the example above, a domain allows people to find and visit your site from their web browser.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
            }
            .padding(.init(top: 16, leading: 8, bottom: 16, trailing: 8))
        }
        .cornerRadius(Constants.innerCornerRadius)
        .border(.white.opacity(0.2), width: 1)
    }
}

struct SiteCreationEmptySiteTemplate_Previews: PreviewProvider {
    static var previews: some View {
        SiteCreationEmptySiteTemplate()
    }
}
