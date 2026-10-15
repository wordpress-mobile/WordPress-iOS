import SwiftUI
import DesignSystem

/// Offers the search's free WordPress.com address above the paid domain suggestions.
struct FreeAddressCard: View {
    let address: String
    let onStartFree: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .DS.Padding.double) {
            VStack(alignment: .leading, spacing: .DS.Padding.half) {
                // A line break inside an address misstates it (SwiftUI breaks `wordpress.com` as `wordpress.-com`),
                // so a long address shrinks instead, and is cut in the middle as a last resort.
                Text(address)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .truncationMode(.middle)
                Text(Strings.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            DSButton(
                title: Strings.button,
                style: .init(emphasis: .primary, size: .medium),
                action: onStartFree
            )
            .accessibilityLabel(String(format: Strings.buttonAccessibilityLabel, address))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.DS.Padding.double)
        .background(
            RoundedRectangle(cornerRadius: .DS.Radius.medium)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
    }
}

private enum Strings {
    static let body = NSLocalizedString(
        "siteCreation.domains.freeAddressCard.body",
        value: "Start free and upgrade to a custom domain name anytime.",
        comment:
            "Body of the card offering the free WordPress.com address in Site Creation. The address is the card's title."
    )
    static let button = NSLocalizedString(
        "siteCreation.domains.freeAddressCard.button",
        value: "Start free",
        comment:
            "Button on the card offering the free WordPress.com address in Site Creation. Choosing it moves to the next step."
    )
    static let buttonAccessibilityLabel = NSLocalizedString(
        "siteCreation.domains.freeAddressCard.buttonAccessibilityLabel",
        value: "Start free with %1$@",
        comment:
            "Accessibility label of the button on the card offering the free WordPress.com address in Site Creation. %1$@ is the free address, for example example.wordpress.com."
    )
}

#Preview {
    VStack {
        FreeAddressCard(address: "bluebirdbakery.wordpress.com", onStartFree: {})
        FreeAddressCard(address: "bluebirdbakeryspeedandcoffeeroasters1015.wordpress.com", onStartFree: {})
    }
    .padding()
}
