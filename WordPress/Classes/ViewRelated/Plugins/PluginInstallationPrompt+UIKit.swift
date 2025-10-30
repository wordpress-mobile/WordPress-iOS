import UIKit
import SwiftUI
import WordPressCoreProtocols

class PluginInstallationPromptViewController: UIHostingController<PluginInstallationPrompt> {

    typealias ActionCallback = (PluginInstallationResult) -> Void

    @MainActor
    public init(plugin: RecommendedPlugin, installer: any PluginInstallerProtocol, wasDismissed: ActionCallback? = nil) {
        super.init(rootView: PluginInstallationPrompt(
            plugin: plugin,
            installer: installer,
            wasDismissed: wasDismissed
        ))
    }

    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
