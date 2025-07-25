import SwiftUI

struct TopListArchiveSectionRowView: View {
    let item: TopListData.ArchiveSection
    let showDetails: Bool
    var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.forward")
                    .frame(width: 16)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.none, value: isExpanded)
                
                Text(localizedSectionName)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.trailing, 4)
        }
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
