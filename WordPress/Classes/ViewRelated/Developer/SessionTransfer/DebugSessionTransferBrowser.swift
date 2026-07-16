import Foundation
import Network

/// Browses for session-transfer receivers advertising `_wpcom-login._tcp` on the local network, so
/// the token-holder can pick one to log in. The `bonjourWithTXTRecord` descriptor delivers each
/// receiver's advertised metadata (`DebugSessionReceiverInfo`) directly in the browse result, so no
/// separate resolve step is needed. Debug/internal builds only.
final class DebugSessionTransferBrowser: ObservableObject {
    struct DiscoveredReceiver: Identifiable, Equatable {
        /// The Bonjour service instance name — unique per advertised receiver.
        let id: String
        let info: DebugSessionReceiverInfo
        let endpoint: NWEndpoint
    }

    @Published private(set) var receivers: [DiscoveredReceiver] = []

    private var browser: NWBrowser?

    func start() {
        let descriptor = NWBrowser.Descriptor.bonjourWithTXTRecord(
            type: DebugSessionTransferReceiver.bonjourServiceType,
            domain: nil
        )
        let browser = NWBrowser(for: descriptor, using: NWParameters())
        self.browser = browser
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            self?.receivers = Self.parse(results)
        }
        browser.start(queue: .main)
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }

    private static func parse(_ results: Set<NWBrowser.Result>) -> [DiscoveredReceiver] {
        results
            .compactMap { result -> DiscoveredReceiver? in
                guard case .bonjour(let txtRecord) = result.metadata,
                    let info = DebugSessionReceiverInfo(txtDictionary: txtRecord.dictionary),
                    case .service(let name, _, _, _) = result.endpoint
                else {
                    return nil
                }
                return DiscoveredReceiver(id: name, info: info, endpoint: result.endpoint)
            }
            .sorted { $0.info.name.localizedCaseInsensitiveCompare($1.info.name) == .orderedAscending }
    }
}
