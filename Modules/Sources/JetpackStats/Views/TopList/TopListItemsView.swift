import SwiftUI

struct TopListItemsView: View {
    let data: TopListChartData
    let itemLimit: Int
    let showDetails: Bool
    let showMoreButton: Bool
    let onShowMore: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Constants.step1 / 2) {
                ForEach(data.items.prefix(itemLimit), id: \.current.id) { item in
                    TopListItemView(
                        currentItem: item.current,
                        previousItem: item.previous,
                        metric: data.metric,
                        maxValue: data.maxValue,
                        showDetails: showDetails
                    )
                    .transition(.opacity)
                }
                // Add empty rows if needed to maintain consistent height
                let itemsToShow = data.items.prefix(itemLimit).count
                if itemsToShow < itemLimit {
                    ForEach(itemsToShow..<itemLimit, id: \.self) { _ in
                        emptyRowView
                    }
                }
            }
            .animation(.spring, value: data.items.map(\.current.id))

            if showMoreButton {
                showMoreButtonView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .disabled(data.items.count <= itemLimit)
            }
        }
    }

    private var emptyRowView: some View {
        HStack {
            Text("")
                .font(.callout)
        }
        .frame(height: showDetails ? 44 : 36)
        .frame(maxWidth: .infinity)
    }

    private var showMoreButtonView: some View {
        Button {
            onShowMore?()
        } label: {
            HStack(spacing: 4) {
                Text(Strings.Buttons.showAll)
                    .padding(.trailing, 4)
                    .font(.callout)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .font(.body)
        }
        .padding(.top, 16)
        .padding(.leading, 12)
        .tint(Color.secondary.opacity(0.8))
    }
}
