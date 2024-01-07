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
        let rows: [Row]
        let action: Action?
    }

    private let input: Input

    init(input: Input) {
        self.input = input
    }

    var body: some View {
        VStack(spacing: Length.Padding.single) {
            featureImage
            rowsVStack
            actionHStack
        }
        .padding(.bottom, Length.Padding.single)
        .padding(.horizontal, Length.Padding.double)
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    var featureImage: some View {
        if let featureImageURL = input.featureImageURL {
            AsyncImage(url: featureImageURL) { phase in
                Group {
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Color.DS.Background.secondary
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Length.Radius.small
                    )
                )
            }
        }
    }

    @ViewBuilder
    var rowsVStack: some View {
        VStack(spacing: Length.Padding.single) {
            ForEach(input.rows) { row in
                HStack(alignment: .top, spacing: Length.Padding.split) {
                    if let imageURL = row.imageURL {
                        AsyncImage(url: imageURL)
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
                                .foregroundStyle(Color.DS.Foreground.primary)
                        }

                        if let description = row.description {
                            Text(description)
                                .style(.bodySmall(.regular))
                                .foregroundStyle(Color.DS.Foreground.secondary)
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

// DesignSystem.DSButtonStyle extension to omit `isJetpack` from project target.
extension DSButtonStyle {
    init(emphasis: DSButtonStyle.Emphasis, size: DSButtonStyle.Size) {
        self.init(
            emphasis: emphasis,
            size: size,
            isJetpack: AppConfiguration.isJetpack
        )
    }
}

#if DEBUG
struct DynamicDashboardCard_Previews: PreviewProvider {
    static var previews: some View {
        DynamicDashboardCard(
            input: .init(
                featureImageURL: URL(string: "https://i.pickadummy.com/index.php?imgsize=400x200")!,
                rows: [
                    .init(
                        title: "Title first",
                        description: "Description first",
                        imageURL: URL(string: "https://i.pickadummy.com/index.php?imgsize=48x48")!
                    ),
                    .init(
                        title: "Title second",
                        description: "Description second",
                        imageURL: URL(string: "https://i.pickadummy.com/index.php?imgsize=48x48")!
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
