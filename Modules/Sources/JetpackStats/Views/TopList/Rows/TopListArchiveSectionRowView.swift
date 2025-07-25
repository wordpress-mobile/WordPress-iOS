import SwiftUI

struct TopListArchiveSectionRowView: View {
    let item: TopListData.ArchiveSection
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

            Text(localizedSectionName)
                .font(.callout)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.trailing, 4)
    }
    
    private var localizedSectionName: String {
        switch item.sectionName.lowercased() {
        case "author":
            return Strings.ArchiveSections.author
        case "other":
            return Strings.ArchiveSections.other
        default:
            // Fallback to capitalized for any unknown sections
            return item.sectionName.capitalized
        }
    }
}
