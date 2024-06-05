import SwiftUI
import DesignSystem

struct MilestoneView: View {
    private enum Constants {
        static let milestoneImageDiameter: CGFloat = 136
        static let accentColorHeight: CGFloat = 281
    }

    private let milestoneImageURL: URL
    private let accentColor: Color?
    private let title: String

    init(
        milestoneImageURL: URL,
        accentColor: Color?,
        title: String
    ) {
        self.milestoneImageURL = milestoneImageURL
        self.accentColor = accentColor
        self.title = title
    }

    var body: some View {
        contentVStack
    }

    private var contentVStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .top) {
                accentGradient
                milestoneImage
                    .padding(.top, .DS.Padding.large)
            }
            Group {
                titleText
                    .padding(.bottom, .DS.Padding.double)
                AuthorView(
                    avatarURL: milestoneImageURL,
                    title: "Endurance Voyage",
                    subtitle: "ernestshackleton.com"
                )
                Spacer()

                DSButton(
                    title: "Share milestone",
                    iconName: .blockShare,
                    style: .init(
                        emphasis: .primary,
                        size: .large,
                        isJetpack: AppConfiguration.isJetpack
                    )
                ) {

                }
                .padding(.bottom, .DS.Padding.double)
            }
            .padding(.horizontal, .DS.Padding.medium)
        }
    }

    @ViewBuilder
    private var accentGradient: some View {
        if let accentColor {
            LinearGradient(
                colors: [
                    accentColor.opacity(0.5),
                    accentColor.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(
                height: Constants.accentColorHeight
            )
            .ignoresSafeArea(edges: .top)
        }
    }

    private var milestoneImage: some View {
        CachedAsyncImage(url: milestoneImageURL)
            .frame(
                width: Constants.milestoneImageDiameter,
                height: Constants.milestoneImageDiameter
            )
            .clipShape(Circle())
    }

    private var titleText: some View {
        Text(title)
            .font(.DS.heading2)
    }
}

#Preview {
    MilestoneView(
        milestoneImageURL: URL(
            string: "https://fastly.picsum.photos/id/118/136/136.jpg?hmac=awxrwstCvwE4TbHX1BAVRAfBfjylou8s0NpL5Q-yUko"
        )!,
        accentColor: .orange,
        title: "Happy aniversary with WordPress! "
    )
}
