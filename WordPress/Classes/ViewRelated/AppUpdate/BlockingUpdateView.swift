import SwiftUI
import DesignSystem
import UIKit
import StoreKit
import WordPressShared

final class BlockingUpdateViewController: UIHostingController<BlockingUpdateView> {
    init(viewModel: AppStoreInfoViewModel, onButtonTapped: @escaping () -> Void) {
        super.init(rootView: .init(viewModel: viewModel, onButtonTapped: onButtonTapped))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct BlockingUpdateView: View {
    let viewModel: AppStoreInfoViewModel
    let onButtonTapped: (() -> Void)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.title)
                .font(.system(.title))
                .fontWeight(.heavy)
                .foregroundStyle(.primary)
                .padding(.top, 24)

            Text(viewModel.message)
                .font(.system(.body))
                .foregroundStyle(.secondary)

            appInfoView
                .padding([.top, .bottom], 16)

            ScrollView {
                whatsNewView
            }

            DSButton(title: viewModel.latestVersionButtonTitle, style: .init(emphasis: .primary, size: .large)) {
                onButtonTapped()
            }
            .padding(.bottom, 20)
        }
        .padding([.leading, .trailing], 20)
        .interactiveDismissDisabled()
        .onAppear {
            WPAnalytics.track(.inAppUpdateShown, properties: ["type": "blocking"])
        }
    }

    private var appInfoView: some View {
        HStack(spacing: 12) {
            if let appIconImage = UIImage(named: AppIcon.defaultIcon.imageName) {
                Image(uiImage: appIconImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40)
                    .cornerRadius(10)
            }

            VStack(alignment: .leading) {
                Text(viewModel.appName)
                    .font(.system(.callout))
                    .foregroundStyle(.primary)
                Text(viewModel.version)
                    .font(.system(.callout))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var whatsNewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.whatsNewTitle)
                .font(.system(.callout))
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            ForEach(viewModel.releaseNotes, id: \.self) { note in
                Text(note)
                    .font(.system(.callout))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
