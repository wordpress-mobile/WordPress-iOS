import SwiftUI

struct DomainsFABMenuView: View {
    enum Action: String, CaseIterable, Identifiable {
        case addToSite
        case purchase
        case transfer

        var id: String {
            rawValue
        }

        var title: String {
            switch self {
            case .addToSite:
                return NSLocalizedString(
                    "domain.management.fab.add.domain.title",
                    value: "Add domain to site",
                    comment: "Domain Management FAB Add Domain title"
                )
            case .purchase:
                return NSLocalizedString(
                    "domain.management.fab.purchase.domain.title",
                    value: "Purchase domain only",
                    comment: "Domain Management FAB Purchase Domain title"
                )
            case .transfer:
                return NSLocalizedString(
                    "domain.management.fab.transfer.domain.title",
                    value: "Transfer domain(s)",
                    comment: "Domain Management FAB Transfer Domain title"
                )
            }
        }
    }

    @Binding var selectedAction: Action

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Action.allCases) { action in
                menuButton(action: action)
                    .padding(.horizontal, Length.Padding.double)
                if action != .transfer {
                    Divider()
                }
            }
        }
        .fixedSize()
        .padding(.vertical, Length.Padding.single)
        .background(Color.DS.Background.primary)
        .cornerRadius(Length.Padding.double)
    }

    private func menuButton(action: Action) -> some View {
        Button {
            self.selectedAction = action
        } label: {
            Text(action.title)
                .foregroundColor(.DS.Foreground.primary)
                .font(.title3)
        }
        .frame(height: Length.Hitbox.minTapDimension)
    }
}

struct DomainsFABMenuView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.DS.Background.quaternary
                .ignoresSafeArea()
            DomainsFABMenuView(selectedAction: .constant(.addToSite))
                .padding()
        }
    }
}
