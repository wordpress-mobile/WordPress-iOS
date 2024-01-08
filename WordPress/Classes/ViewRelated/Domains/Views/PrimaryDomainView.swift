import SwiftUI
import DesignSystem

struct PrimaryDomainView: View {
    var body: some View {
        Group {
            HStack(spacing: Length.Padding.half) {
                Image(systemName: "globe")
                    .font(.callout)
                    .foregroundStyle(Color.DS.Foreground.primary)
                Text(Strings.primaryDomain)
                    .font(.callout)
                    .foregroundStyle(Color.DS.Foreground.primary)
            }
            .padding(.vertical, Length.Padding.half)
            .padding(.horizontal, Length.Padding.single)
        }
        .background(Color.DS.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: Length.Radius.small))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Strings.primaryDomain)
    }
}

private extension PrimaryDomainView {
    enum Strings {
        static let primaryDomain = NSLocalizedString("site.domains.primaryDomain.title",
                                                     value: "Primary domain",
                                                     comment: "Primary domain label, used in the site address section of the Domains Dashboard.")
    }
}
