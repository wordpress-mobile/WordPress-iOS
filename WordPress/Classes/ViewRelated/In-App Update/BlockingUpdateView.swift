import SwiftUI
import DesignSystem
import UIKit
import StoreKit

struct BlockingUpdateViewModel {
    var appName: String = "Jetpack iOS"
    var latestVersion: String = "24.9"
    var fileSizeBytes: String = "5MB"
    var releaseNotes: [String] = ["We fixed a bug!", "We fixed another important bug!"]
}

final class BlockingUpdateViewController: UIHostingController<BlockingUpdateView> {
    init(viewModel: BlockingUpdateViewModel) {
        super.init(rootView: .init(viewModel: viewModel))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func show() {
        guard let window = UIApplication.sharedIfAvailable()?.mainWindow,
              let topViewController = window.topmostPresentedViewController,
              !((topViewController as? UINavigationController)?.viewControllers.first is BlockingUpdateViewController) else {
            wpAssertionFailure("Failed to show blocking update view")
            return
        }
        let controller = BlockingUpdateViewController(viewModel: BlockingUpdateViewModel())
        let navigation = UINavigationController(rootViewController: controller)
        topViewController.present(navigation, animated: true)
    }
}

struct BlockingUpdateView: View {
    let viewModel: BlockingUpdateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.title)
                .font(.system(.title))
                .fontWeight(.heavy)
                .foregroundStyle(.primary)
                .padding(.top, 24)

            Text(Strings.description)
                .font(.system(.body))
                .foregroundStyle(.secondary)

            appInfoView
                .padding([.top, .bottom], 16)

            whatsNewView

            Spacer()

            buttonsView
        }
        .padding([.leading, .trailing], 20)
        .interactiveDismissDisabled()
        .onAppear {
            // Todo: track event
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
                Text("\(viewModel.latestVersion) · \(viewModel.fileSizeBytes)")
                    .font(.system(.callout))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var whatsNewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.whatsNew)
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

    private var buttonsView: some View {
        VStack {
            DSButton(title: Strings.Button.update, style: .init(emphasis: .primary, size: .large)) {
                showAppStore()
            }
            DSButton(title: Strings.Button.moreInfo, style: .init(emphasis: .tertiary, size: .large)) {
                showMoreInfo()
            }
        }
    }

    private func showAppStore() {
        // Todo
    }

    private func showMoreInfo() {
        // Todo
    }
}

private enum Strings {
    static let title = NSLocalizedString("blockingUpdate.title", value: "App Update Available", comment: "Title for the blocking version update screen")
    static let description = NSLocalizedString("blockingUpdate.description", value: "Your app version is out of date. To use this app, download the latest version.", comment: "Description for the blocking version update screen")
    static let whatsNew = NSLocalizedString("blockingUpdate.whatsNew", value: "What's New", comment: "Section title for what's new in hte blocking version update screen")

    enum Button {
        static let update = NSLocalizedString("blockingUpdate.button.update", value: "Update", comment: "Title for button that shows the app store listing when tapped")
        static let moreInfo = NSLocalizedString("blockingUpdate.button.moreInfo", value: "More info", comment: "Title for button that shows more information about the update when tapped")
    }
}
