import SwiftUI
import WebKit

/// A native SwiftUI implementation of an interactive map view that displays SVG maps
/// with data-driven coloring of regions.
///
/// This view replaces the legacy FSInteractiveMap due to the performance issues
/// with the previous implementation, particularly around rendering and excessive
/// memory usage.
///
/// ## Implementation Details
///
/// The view uses WKWebView for rendering SVG content, which is the optimal approach
/// on iOS for several reasons:
/// - **Native SVG Support**: WKWebView provides the most complete and accurate SVG
///   rendering on iOS, supporting all SVG features including complex paths, gradients,
///   and transformations.
/// - **Performance**: WebKit's rendering engine is highly optimized for vector graphics
///   and provides hardware acceleration.
/// - **Memory Efficiency**: Unlike UIKit-based approaches that rasterize SVG to bitmaps,
///   WKWebView maintains the vector nature of the content.
/// - **Smooth Animations**: CSS transitions and transforms are hardware-accelerated.
///
/// The view processes SVG files by:
/// 1. Loading the SVG resource from the bundle
/// 2. Dynamically updating fill colors based on data values
/// 3. Applying theme-appropriate styling for light/dark modes
/// 4. Wrapping the SVG in minimal HTML for optimal display
///
/// ## Usage Example
/// ```swift
/// InteractiveMapView(
///     data: ["US": 1000, "GB": 750, "CA": 500],
///     configuration: .init(tintColor: .blue)
/// )
/// ```
struct InteractiveMapView: View {
    struct Configuration {
        let lightStyle: MapStyle
        let darkStyle: MapStyle

        init(lightStyle: MapStyle, darkStyle: MapStyle) {
            self.lightStyle = lightStyle
            self.darkStyle = darkStyle
        }

        init(tintColor: UIColor) {
            self.lightStyle = MapStyle(
                colorAxis: [
                    tintColor.lightened(by: 0.75),
                    tintColor
                ],
                strokeColor: UIColor(white: 0.8, alpha: 1),
                fillColor: UIColor(white: 0.94, alpha: 1)
            )
            self.darkStyle = MapStyle(
                colorAxis: [
                    tintColor.lightened(by: 0.7),
                    tintColor
                ],
                strokeColor: UIColor(white: 0.36, alpha: 1),
                fillColor: UIColor(white: 0.19, alpha: 1)
            )
        }
    }

    let svgResourceName: String
    let data: [String: Int]
    let configuration: Configuration
    @Binding var selectedCountryCode: String?

    init(
        svgResourceName: String = "world-map",
        data: [String: Int],
        configuration: Configuration,
        selectedCountryCode: Binding<String?>
    ) {
        self.svgResourceName = svgResourceName
        self.data = data
        self.configuration = configuration
        self._selectedCountryCode = selectedCountryCode
    }

    @State private var processedSVG: String?

    @Environment(\.colorScheme) private var colorScheme

    private struct Parameters: Equatable {
        let data: [String: Int]
        let colorScheme: ColorScheme
    }

    private var parameters: Parameters {
        Parameters(data: data, colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            if let processedSVG {
                SVGWebView(htmlContent: processedSVG, selectedCountryCode: $selectedCountryCode)
            }
        }
        .task(id: parameters) {
            await updateMap(parameters: parameters)
        }
    }

    @MainActor
    private func updateMap(parameters: Parameters) async {
        guard let svgContent = await loadSVG(resourceName: svgResourceName) else {
            return
        }

        // Get the style for the current color scheme
        let baseStyle = parameters.colorScheme == .dark ? configuration.darkStyle : configuration.lightStyle

        // Resolve colors in the current trait collection
        let traitCollection = UITraitCollection(userInterfaceStyle: parameters.colorScheme == .dark ? .dark : .light)
        let resolvedStyle = MapStyle(
            colorAxis: baseStyle.colorAxis.map { $0.resolvedColor(with: traitCollection) },
            strokeColor: baseStyle.strokeColor.resolvedColor(with: traitCollection),
            fillColor: baseStyle.fillColor.resolvedColor(with: traitCollection)
        )
        let processedSVGContent = await processSVG(
            svgContent: svgContent,
            data: parameters.data,
            style: resolvedStyle
        )
        guard !Task.isCancelled else { return }
        self.processedSVG = wrapSVGInHTML(processedSVGContent)
    }

    private func wrapSVGInHTML(_ svg: String) -> String {
        // Load HTML template from resources
        guard let templatePath = Bundle.module.path(forResource: "interactive-map-template", ofType: "html"),
              let template = try? String(contentsOfFile: templatePath) else {
            // Fallback to inline HTML if template not found
            return "<html><body>\(svg)</body></html>"
        }

        // Replace placeholder with SVG content
        return template.replacingOccurrences(of: "<!-- SVG_CONTENT_PLACEHOLDER -->", with: svg)
    }
}

struct MapStyle {
    let colorAxis: [UIColor]
    let strokeColor: UIColor
    let fillColor: UIColor
}

// MARK: - SVG Processing

private func loadSVG(resourceName: String) async -> String? {
    // Try multiple approaches to load the SVG
    if let svgPath = Bundle.module.path(forResource: resourceName, ofType: "svg"),
       let content = try? String(contentsOfFile: svgPath) {
        return content
    }
    return nil
}

private func processSVG(
    svgContent: String,
    data: [String: Int],
    style: MapStyle
) async -> String {
    // Find min and max values in the data
    let values = data.values
    let minValue = values.min() ?? 0
    let maxValue = values.max() ?? 1

    var processedContent = svgContent

    // Process each country in the data
    for (countryCode, value) in data {
        // Handle single data point case where min == max
        let normalizedValue: Double
        if minValue == maxValue {
            normalizedValue = 1.0 // Use max color for single data point
        } else {
            normalizedValue = Double(value - minValue) / Double(maxValue - minValue)
        }
        let color = interpolateColor(normalizedValue, colorAxis: style.colorAxis)

        // Replace fill color for paths with matching country codes
        processedContent = processCountryInSVG(processedContent, countryCode: countryCode, color: color)
    }

    // Update default fill color for countries without data
    processedContent = updateDefaultColors(processedContent, strokeColor: style.strokeColor, fillColor: style.fillColor)

    return processedContent
}

private func processCountryInSVG(_ svg: String, countryCode: String, color: UIColor) -> String {
    var result = svg
    let hexColor = color.toHex()

    // Look for path elements with country code as ID
    // The SVG uses id="XX" where XX is the 2-letter country code
    let pattern = "(<path\\s+id=\"\(countryCode)\"[^>]*?)(?:fill=\"[^\"]*\")?([^>]*?>)"

    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
        let range = NSRange(location: 0, length: result.utf16.count)
        result = regex.stringByReplacingMatches(
            in: result,
            options: [],
            range: range,
            withTemplate: "$1 fill=\"\(hexColor)\" style=\"fill:\(hexColor)\"$2"
        )
    }

    return result
}

private func updateDefaultColors(_ svg: String, strokeColor: UIColor, fillColor: UIColor) -> String {
    var result = svg

    // First, update the CSS class that defines default colors
    let fillHex = fillColor.toHex()
    let strokeHex = strokeColor.toHex()

    // Replace the .st0 class definition in the style tag
    result = result.replacingOccurrences(
        of: "\\.st0\\{[^}]*\\}",
        with: ".st0{fill:\(fillHex);stroke:\(strokeHex);stroke-width:1.0;}",
        options: .regularExpression
    )

    return result
}

private func interpolateColor(_ value: Double, colorAxis: [UIColor]) -> UIColor {
    // Ensure we have at least 2 colors
    guard colorAxis.count >= 2 else {
        return colorAxis.first ?? .blue
    }

    // Clamp value between 0 and 1
    let clampedValue = min(max(value, 0), 1)

    if colorAxis.count == 2 {
        // Simple interpolation between two colors
        return UIColor.interpolate(from: colorAxis[0], to: colorAxis[1], fraction: clampedValue)
    } else {
        // Multi-stop gradient interpolation
        let scaledValue = clampedValue * Double(colorAxis.count - 1)
        let lowerIndex = Int(scaledValue)
        let upperIndex = min(lowerIndex + 1, colorAxis.count - 1)
        let fraction = scaledValue - Double(lowerIndex)

        return UIColor.interpolate(
            from: colorAxis[lowerIndex],
            to: colorAxis[upperIndex],
            fraction: fraction
        )
    }
}

// MARK: - SVG WebView

private struct SVGWebView: UIViewRepresentable {
    let htmlContent: String
    @Binding var selectedCountryCode: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedCountryCode: $selectedCountryCode)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        // Add message handlers for JavaScript communication
        configuration.userContentController.add(context.coordinator.scriptMessageHandler, name: "countrySelected")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        // Disable zooming
        webView.scrollView.maximumZoomScale = 1.0
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.isMultipleTouchEnabled = false

        webView.alpha = 0

        context.coordinator.webView = webView

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Force reload by clearing cache when color scheme changes
        context.coordinator.setHTML(htmlContent)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var selectedCountryCode: String?
        weak var webView: WKWebView?

        private var htmlContent: String?
        private var isReloadNeeded = false
        private var lastReloadDate: Date?

        let scriptMessageHandler: ScriptMessageHandler

        init(selectedCountryCode: Binding<String?>) {
            self._selectedCountryCode = selectedCountryCode
            self.scriptMessageHandler = ScriptMessageHandler()

            super.init()

            scriptMessageHandler.coordinator = self

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(Coordinator.applicationWillEnterForeground),
                name: UIApplication.willEnterForegroundNotification,
                object: nil
            )
        }

        func setHTML(_ html: String) {
            self.htmlContent = html
            webView?.loadHTMLString(html, baseURL: nil)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Fade in when content is loaded
            UIView.animate(withDuration: 0.3, delay: 0.05, options: .curveEaseIn) {
                webView.alpha = 1
            }
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            isReloadNeeded = true
            if UIApplication.shared.applicationState == .active {
                reloadIfNeeded()
            }
        }

        @objc private func applicationWillEnterForeground() {
            reloadIfNeeded()
        }

        private func reloadIfNeeded() {
            guard isReloadNeeded,
                  Date.now.timeIntervalSince((lastReloadDate ?? .distantPast)) > 8,
                  let webView,
                  let htmlContent else {
                return
            }
            isReloadNeeded = false
            lastReloadDate = Date()
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "countrySelected" {
                DispatchQueue.main.async {
                    if let countryCode = message.body as? String {
                        self.selectedCountryCode = countryCode
                    } else {
                        self.selectedCountryCode = nil
                    }
                }
            }
        }

        class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
            weak var coordinator: Coordinator?

            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                coordinator?.userContentController(userContentController, didReceive: message)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    InteractiveMapView(
        data: [
            "US": 15000,
            "GB": 8500,
            "CA": 6200,
            "DE": 5100,
            "FR": 4800,
            "JP": 4200,
            "AU": 3500,
            "NL": 2800,
            "IT": 2400,
            "ES": 2100,
            "BR": 1900,
            "IN": 1700,
            "MX": 1500,
            "SE": 1200,
            "NO": 1000,
            "PL": 900,
            "CH": 850,
            "BE": 800,
            "AT": 750,
            "DK": 700,
            "FI": 650,
            "NZ": 600,
            "IE": 550,
            "PT": 500,
            "CZ": 450
        ],
        configuration: .init(tintColor: Constants.Colors.uiColorBlue), selectedCountryCode: .constant(nil)
    )
    .frame(height: 230)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Constants.Colors.secondaryBackground)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
}
