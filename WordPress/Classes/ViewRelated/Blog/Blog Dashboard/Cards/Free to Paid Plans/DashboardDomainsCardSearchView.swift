import SwiftUI

struct DashboardDomainsCardSearchView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Image(systemName: Constants.iconName)
                    .foregroundColor(Colors.icon)
                    .font(.system(size: Metrics.iconSize))
                Text(Constants.searchBarPlaceholder)
                    .foregroundColor(Colors.text)
                    .font(.system(size: Metrics.fontSize))
                Spacer()
            }
            .padding(.horizontal, Metrics.padding)
            .frame(height: Metrics.searchBarHeight)
            .background(
                RoundedRectangle(cornerRadius: Metrics.containerCornerRadius)
                    .foregroundColor(Colors.containerBackground)
            )
            Spacer()
            RoundedRectangle(cornerRadius: Metrics.containerCornerRadius)
                .foregroundColor(Colors.containerBackground)
        }
        .padding([.leading, .trailing, .top], Metrics.padding)
        .frame(height: Metrics.height)
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(
                        colors: [
                            colorScheme == .light ? Colors.gradientTopLight : Colors.gradientTopDark,
                            Color.clear
                        ]
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(Metrics.cornerRadius)
        .accessibilityHidden(true)
    }
}

private extension DashboardDomainsCardSearchView {
    enum Metrics {
        static let padding: CGFloat = 8
        static let cornerRadius: CGFloat = 16
        static let containerCornerRadius: CGFloat = 8
        static let iconSize: CGFloat = 20
        static let fontSize: CGFloat = 15 // fixed .footnote style size
        static let height: CGFloat = 110
        static let searchBarHeight: CGFloat = 40
    }

    enum Constants {
        static let iconName = "globe"
        static let searchBarPlaceholder = "yourgroovydomain.com"
    }

    enum Colors {
        static let gradientTopLight = Color(UIColor.secondarySystemBackground)
        static let gradientTopDark = Color(UIColor.tertiarySystemBackground)
        static let containerBackground = Color(UIColor.secondarySystemGroupedBackground)
        static let icon = Color(UIColor.jetpackGreen)
        static let text = Color(UIColor.textSubtle)
    }
}
