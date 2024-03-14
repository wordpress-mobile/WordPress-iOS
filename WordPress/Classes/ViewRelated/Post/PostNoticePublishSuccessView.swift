import Foundation
import SwiftUI
import DesignSystem

// TODO: add l10n
struct PostNoticePublishSuccessView: View {
    let post: AbstractPost
    let onDoneTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 33) {
            Spacer()

            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Post published!")
                        .font(.subheadline)

                    Text(post.titleForDisplay())
                        .font(.title3.weight(.semibold))

                    Button(action: {
                        // TODO: action for viewing
                    }, label: {
                        HStack {
                            // TODO: cut in the middle
                            let domain = post.blog.primaryDomainAddress
                            if !domain.isEmpty {
                                Text("View on \(domain)")
                            } else {
                                Text("View")
                            }
                            Image("icon-post-actionbar-view")
                        }
                        .font(.subheadline)
                        .lineLimit(1)
                    })
                    .tint(.secondary)
                }

                Spacer()

                Image("post-published")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 90)
            }

            VStack(alignment: .leading, spacing: 16) {
                Text("Get more traffic:")
                HStack {
                    Button(action: {}, label: {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share post")
                        }
                    })
                    Button(action: {}, label: {
                        HStack(alignment: .center) {
                            Image("icon-blaze").renderingMode(.template)
                            Text("Promote with Blaze")
                        }
                    })
                }
            }
            .buttonStyle(PublishSuccessSecondaryButtonStyle())

            Spacer()

            // TOOD: repalce isJetpack
            DSButton(title: "Done", style: .init(emphasis: .primary, size: .large, isJetpack: true), action: onDoneTapped)
        }
        .dynamicTypeSize(.medium ... .accessibility3)
        .padding()
        .navigationBarBackButtonHidden()
    }
}

private struct PublishSuccessSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minHeight: 24)
            .lineLimit(1)
            .font(.subheadline.weight(.medium))
            .tint(configuration.isPressed ? .secondary : .primary)
            .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
            .foregroundStyle(.tint)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(.tertiary, lineWidth: 1)
            )
    }
}
