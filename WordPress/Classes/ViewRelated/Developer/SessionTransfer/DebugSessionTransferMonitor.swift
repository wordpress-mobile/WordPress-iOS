import BuildSettingsKit
import Combine
import SwiftUI
import UIKit
import WordPressUI

/// Watches the local network for devices asking for login help while the app is in the foreground,
/// and offers to log them in with this device's WordPress.com session — the "someone nearby wants to
/// sign in" side of session transfer.
///
/// Opt-in: browsing only runs while `isEnabled` is true, so the iOS Local Network permission prompt
/// never appears unless the user turns the feature on in the debug settings. Debug/internal builds
/// only. Foreground only — it stops when the app resigns active, so there is no background radio cost
/// and no background mode is needed.
@MainActor
final class DebugSessionTransferMonitor {
    static let shared = DebugSessionTransferMonitor()

    private static let enabledDefaultsKey = "debug-session-transfer-monitor-enabled"

    /// Whether the monitor may browse. Off by default; the debug setting flips it. Assigning it
    /// starts or stops browsing immediately (subject to being foreground and an internal build).
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledDefaultsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: enabledDefaultsKey)
            shared.updateActivation()
        }
    }

    private let browser = DebugSessionTransferBrowser()
    private var receiversObserver: AnyCancellable?
    private var isForeground = false
    private var lifecycleStarted = false

    /// The receiver whose consent sheet is currently on screen, if any — so only one is offered at a
    /// time.
    private var presentedReceiverID: String?
    private weak var presentedController: UIViewController?
    /// Receivers already offered during this browse session, so a steady advertisement doesn't
    /// re-prompt after the user dismisses it.
    private var offeredReceiverIDs: Set<String> = []

    private init() {}

    /// Begins observing the app's foreground lifecycle. Safe to call once at launch; browsing itself
    /// still only starts once the feature is enabled.
    func start() {
        guard BuildConfiguration.current.isInternal, !lifecycleStarted else { return }
        lifecycleStarted = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        isForeground = UIApplication.shared.applicationState == .active
        updateActivation()
    }

    @objc private func appDidBecomeActive() {
        isForeground = true
        updateActivation()
    }

    @objc private func appWillResignActive() {
        isForeground = false
        updateActivation()
    }

    private func updateActivation() {
        if Self.isEnabled, isForeground, BuildConfiguration.current.isInternal {
            startBrowsing()
        } else {
            stopBrowsing()
        }
    }

    private func startBrowsing() {
        guard receiversObserver == nil else { return }
        receiversObserver = browser.$receivers.sink { [weak self] receivers in
            self?.offerHelp(for: receivers)
        }
        browser.start()
    }

    private func stopBrowsing() {
        guard receiversObserver != nil else { return }
        browser.stop()
        receiversObserver = nil
        offeredReceiverIDs.removeAll()
    }

    private func offerHelp(for receivers: [DebugSessionTransferBrowser.DiscoveredReceiver]) {
        // Forget devices that have gone away, so they can prompt again if they return.
        offeredReceiverIDs.formIntersection(receivers.map(\.id))

        guard presentedReceiverID == nil,
            AccountHelper.isLoggedIn,
            let receiver = receivers.first(where: { !offeredReceiverIDs.contains($0.id) })
        else {
            return
        }
        present(receiver)
    }

    private func present(_ receiver: DebugSessionTransferBrowser.DiscoveredReceiver) {
        guard let presenter = WordPressAppDelegate.shared?.window?.topmostPresentedViewController else {
            return
        }
        presentedReceiverID = receiver.id
        offeredReceiverIDs.insert(receiver.id)

        let view = DebugSessionTransferConsentView(
            receiver: receiver,
            onSend: { [weak self] in
                self?.presentedController?.dismiss(animated: true)
                Task { await DebugSessionTransferSendService.send(to: receiver) }
            },
            onClose: { [weak self] in
                self?.presentedController?.dismiss(animated: true)
            }
        )
        // Reset on any dismissal — the button actions, or an interactive swipe-down — so the next
        // discovered device can be offered.
        .onDisappear { [weak self] in
            self?.presentedReceiverID = nil
            self?.presentedController = nil
        }

        let controller = UIHostingController(rootView: view)
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = false
        }
        presentedController = controller
        presenter.present(controller, animated: true)
    }
}
