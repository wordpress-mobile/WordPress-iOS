import SwiftUI

@available(iOS 16, *)
struct SiteMonitoringEntryDetailsView: View {
    let text: NSAttributedString

    var body: some View {
        SiteMonitoringTextView(text: text)
            .navigationTitle(Strings.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ShareLink(item: text.string) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
    }
}

private struct SiteMonitoringTextView: UIViewRepresentable {
    let text: NSAttributedString
    var isScrollEnabled = true

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.attributedText = text
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.adjustsFontForContentSizeCategory = true
        textView.autocorrectionType = .no
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Do nothing
    }
}

extension AtomicErrorLogEntry {
    var attributedDescription: NSAttributedString {
        makeAttributedText(metadata: [
            (Strings.metadataKeyTimestamp, timestamp.map(makeString)),
            (Strings.metadataKeyKind, kind),
            (Strings.metadataKeyName, name),
            (Strings.metadataKeyFile, file),
            (Strings.metadataKeyLine, line?.description)
        ], message: message)
    }
}

extension AtomicWebServerLogEntry {
    var attributedDescription: NSAttributedString {
        makeAttributedText(metadata: [
            (Strings.metadataKeyRequestURL, requestUrl),
            (Strings.metadataKeyStatus, status?.description),
            (Strings.metadataKeyTimestamp, date.map(makeString)),
            (Strings.metadataKeyResponseBodySize, bodyBytesSent.map {
                ByteCountFormatter().string(fromByteCount: Int64($0))
            }),
            (Strings.metadataKeyRequestTime, requestTime.map(makeString)),
            (Strings.metadataKeyCached, (cached == "true").description),
            (Strings.metadataKeyHTTPHost, httpHost),
            (Strings.metadataKeyReferrer, httpReferer)
        ])
    }
}

private func makeAttributedText(metadata: [(String, String?)], message: String? = nil) -> NSAttributedString {
    let bold = UIFontMetrics.default.scaledFont(for: .monospacedSystemFont(ofSize: 14, weight: .bold))
    let regular = UIFontMetrics.default.scaledFont(for: .monospacedSystemFont(ofSize: 14, weight: .regular))

    let output = NSMutableAttributedString()
    for (key, value) in metadata {
        output.append(NSAttributedString(string: key, attributes: [.font: bold]))
        output.append(NSAttributedString(string: ": " + (value?.description ?? "–") + "\n", attributes: [.font: regular]))
    }
    if let message {
        output.append(NSAttributedString(string: "\n" + message, attributes: [.font: regular]))
    }
    output.addAttribute(.paragraphStyle, value: {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        return style
    }(), range: NSRange(location: 0, length: output.length))
    output.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: output.length))
    return output
}

private func makeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSXXXXX"
    return formatter.string(from: date)
}

private func makeString(for timeInterval: TimeInterval) -> String {
    let ms = Int(timeInterval.truncatingRemainder(dividingBy: 1) * 1000)
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    return formatter.string(from: timeInterval)! + ".\(String(format: "%0.3d", ms))"
}

private enum Strings {
    static let navigationTitle = NSLocalizedString("siteMonitoring.entryDetailsTitle", value: "Log Entry", comment: "Site Monitoring log entry details navigation title")
    static let metadataKeyTimestamp = NSLocalizedString("siteMonitoring.metadataKeyTimestamp", value: "Timestamp", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyKind = NSLocalizedString("siteMonitoring.metadataKeyKind", value: "Kind", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyName = NSLocalizedString("siteMonitoring.metadataKeyName", value: "Name", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyFile = NSLocalizedString("siteMonitoring.metadataKeyFile", value: "File", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyLine = NSLocalizedString("siteMonitoring.metadataKeyLine", value: "Line", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyRequestURL = NSLocalizedString("siteMonitoring.metadataKeyRequestURL", value: "Request URL", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyStatus = NSLocalizedString("siteMonitoring.metadataKeyStatus", value: "Status", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyResponseBodySize = NSLocalizedString("siteMonitoring.metadataKeyResponseBodySize", value: "Response Size", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyRequestTime = NSLocalizedString("siteMonitoring.metadataKeyRequestTime", value: "Request Time", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyCached = NSLocalizedString("siteMonitoring.metadataKeyCached", value: "Cached", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyHTTPHost = NSLocalizedString("siteMonitoring.metadataKeyHTTPHost", value: "HTTP Host", comment: "Site Monitoring details screen metadata key")
    static let metadataKeyReferrer = NSLocalizedString("siteMonitoring.metadataKeyReferrer", value: "Referrer", comment: "Site Monitoring details screen metadata key")
}

#Preview("AtomicErrorLogEntry") {
    NavigationView {
        if #available(iOS 16, *) {
            SiteMonitoringEntryDetailsView(text: errorLogEntry.attributedDescription)
        }
    }
}

#Preview("AtomicWebServerLogEntry") {
    NavigationView {
        if #available(iOS 16, *) {
            SiteMonitoringEntryDetailsView(text: serverLogEntry.attributedDescription)
        }
    }
}

private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .formatted({
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }())
    return decoder
}()

private let errorLogEntry = try! decoder.decode(AtomicErrorLogEntry.self, from: """
{
    "message": "PHP Warning:  Undefined property: stdClass::$is_pending_icann_verification in /wordpress/plugins/wpcomsh/3.14.21/vendor/automattic/jetpack-mu-wpcom/src/features/launchpad/launchpad-task-definitions.php on line 1015",
    "severity": "Warning",
    "kind": "plugins",
    "name": "wpcomsh",
    "file": "/wordpress/plugins/wpcomsh/3.14.21/vendor/automattic/jetpack-mu-wpcom/src/features/launchpad/launchpad-task-definitions.php",
    "line": 1015,
    "timestamp": "2024-01-23T13:35:16.000Z",
    "atomic_site_id": 150427319
}
""".data(using: .utf8)!)

private let serverLogEntry = try! decoder.decode(AtomicWebServerLogEntry.self, from: """
{
    "body_bytes_sent": 45,
    "cached": "false",
    "date": "2024-01-17T20:57:43.242Z",
    "http2": "",
    "http_host": "creator1516.wpcomstaging.com",
    "http_referer": "https://creator1516.wpcomstaging.com/.well-known/hosting-provider",
    "http_user_agent": "WordPress.com; http://creator1516.wpcomstaging.com",
    "http_version": "HTTP/1.1",
    "http_x_forwarded_for": "192.0.86.102",
    "renderer": "static",
    "request_completion": "OK",
    "request_time": 0.014,
    "request_type": "GET",
    "request_url": "/.well-known/hosting-provider",
    "scheme": "http",
    "status": 200,
    "timestamp": 1705525063,
    "type": "nginx_json",
    "user_ip": "192.0.86.102"
}
""".data(using: .utf8)!)
