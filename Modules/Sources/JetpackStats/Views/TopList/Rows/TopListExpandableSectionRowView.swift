import SwiftUI

struct TopListExpandableSectionRowView: View {
    let item: any TopListExpandableItem
    let showDetails: Bool
    var isExpanded: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.forward")
                .frame(width: 12) // Centering
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: Constants.step2, alignment: .leading)
                .animation(.none, value: isExpanded)

            Text(item.displayName)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.trailing, 4)
    }
}
