import SwiftUI
import WordPressKit
import WordPressUI

struct SubscriberDetailsHeaderView: View {
    let subscriber: SubscribersServiceRemote.SubsciberBasicInfoResponse

    var body: some View {
        HStack(spacing: 12) {
            if subscriber.isDotComUser {
                AvatarView(style: .single(subscriber.avatarURL), diameter: 40)
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(subscriber.displayName ?? "–")
                            .font(.title3.weight(.semibold))
                            .textSelection(.enabled)
                    }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(subscriber.emailAddress ?? "–")
                            .font(.subheadline)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
            } else {
                Image(systemName: "envelope")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)

                Text(subscriber.emailAddress ?? "–")
                    .font(.headline)
                    .textSelection(.enabled)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}
