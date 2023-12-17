import SwiftUI
import DesignSystem

struct DynamicDashboardCard: View {
    private enum Constants {
        static let featureImageHeight: CGFloat = 151
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
    }

    @ViewBuilder
    var featureImage: some View {
        if let featureImageURL = input.featureImageURL {
            AsyncImage(url: featureImageURL)
                .frame(height: Constants.featureImageHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Length.Radius.small
                    )
                )
        }
    }

    @ViewBuilder
    var rowsVStack: some View {
        VStack(spacing: Length.Padding.single) {
            ForEach(input.rows) { row in
                HStack(spacing: Length.Padding.split) {
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
                                .foregroundStyle(Color.DS.Foreground.primary)
                        }

                        if let description = row.description {
                            Text(description)
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

#Preview {
    DynamicDashboardCard(
        input: .init(
            featureImageURL: URL(string: "google.com")!,
            rows: [
                .init(
                    title: "Title first",
                    description: "Description first",
                    imageURL: URL(string: "wordpress.com")!
                ),
                .init(
                    title: "Title second",
                    description: "Description second",
                    imageURL: URL(string: "wordpress.com")!
                )
            ],
            action: .init(title: "Action button", callback: {
                ()
            })
        )
    )
    .padding()
}
