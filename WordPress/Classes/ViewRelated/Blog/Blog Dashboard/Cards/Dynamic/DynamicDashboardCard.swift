import SwiftUI
import DesignSystem

struct DynamicDashboardCard: View {
    private enum Constants {
        static let rowImageDiameter: CGFloat = 48
    }

    struct Input {
        struct Row: Identifiable {
            let id: UUID = UUID()

            let title: String?
            let description: String?
            let imageURL: URL?
        }

        struct Action {
            let title: String?
            let callback: (() -> Void)
        }

        let featureImageURL: URL?
        let featureImageWidthToHeightRatio: CGFloat
        let rows: [Row]
        let action: Action?
    }

    private let input: Input

    init(input: Input) {
        self.input = input
    }

    var body: some View {
        VStack(spacing: .DS.Padding.single) {
            featureImage
            rowsVStack
            actionHStack
        }
        .padding(.bottom, .DS.Padding.single)
        .padding(.horizontal, .DS.Padding.double)
    }

    @ViewBuilder
    var featureImage: some View {
        if let featureImageURL = input.featureImageURL {
            AsyncImage(url: featureImageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(input.featureImageWidthToHeightRatio, contentMode: .fit)
                default:
                        Color(.secondarySystemBackground)
                        .aspectRatio(input.featureImageWidthToHeightRatio, contentMode: .fit)
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: .DS.Radius.small
                )
            )
        }
    }

    @ViewBuilder
    var rowsVStack: some View {
        VStack(spacing: .DS.Padding.single) {
            ForEach(input.rows) { row in
                HStack(alignment: .center, spacing: .DS.Padding.split) {
                    if let imageURL = row.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                            default:
                                    Color(.secondarySystemBackground)
                            }
                        }
                            .frame(
                                width: Constants.rowImageDiameter,
                                height: Constants.rowImageDiameter
                            )
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading) {
                        if let title = row.title {
                            Text(title)
                                .style(.bodyLarge(.emphasized))
                                .foregroundStyle(.primary)
                        }

                        if let description = row.description {
                            Text(description)
                                .style(.bodySmall(.regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    var actionHStack: some View {
        if let title = input.action?.title {
            HStack {
                DSButton(title: title, style: .init(
                    emphasis: .tertiary,
                    size: .small,
                    isJetpack: AppConfiguration.isJetpack
                )) {
                    input.action?.callback()
                }
                Spacer()
            }
        }
    }
}

final class DynamicDashboardCardViewController: UIHostingController<DynamicDashboardCard> {

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.invalidateIntrinsicContentSize()
    }
}

#if DEBUG
struct DynamicDashboardCard_Previews: PreviewProvider {
    static var previews: some View {
        DynamicDashboardCard(
            input: .init(
                featureImageURL: URL(string: "https://i.pickadummy.com/index.php?imgsize=400x200")!,
                featureImageWidthToHeightRatio: 2,
                rows: [
                    .init(
                        title: "Title first",
                        description: "Description first",
                        imageURL: URL(string: "https://mobiledotblog.files.wordpress.com/2024/03/perf-icon.png")!
                    ),
                    .init(
                        title: "Title second",
                        description: "Description second",
                        imageURL: nil
                    )
                ],
                action: .init(title: "Action button", callback: {
                    ()
                })
            )
        )
        .padding()
    }
}
#endif
