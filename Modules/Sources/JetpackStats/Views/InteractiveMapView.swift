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
    struct Style {
        let colorAxis: [Color]
        let strokeColor: Color
        let fillColor: Color
    }
    
    struct Configuration {
        let lightStyle: Style
        let darkStyle: Style
        
        init(lightStyle: Style, darkStyle: Style) {
            self.lightStyle = lightStyle
            self.darkStyle = darkStyle
        }
        
        init(tintColor: Color) {
            self.lightStyle = Style(
                colorAxis: [
                    tintColor.lightened(by: 0.9),
                    tintColor
                ],
                strokeColor: Color.secondary,
                fillColor: Color(.systemGray5)
            )
            self.darkStyle = Style(
                colorAxis: [
                    tintColor.lightened(by: 0.9),
                    tintColor
                ],
                strokeColor: Color(UIColor.secondarySystemGroupedBackground),
                fillColor: Color(.systemBackground)
            )
        }
    }
    
    let svgResourceName: String
    let data: [String: Double]
    let configuration: Configuration
    
    init(
        svgResourceName: String = "world-map",
        data: [String: Double],
        configuration: Configuration
    ) {
        self.svgResourceName = svgResourceName
        self.data = data
        self.configuration = configuration
    }

    @State private var processedSVG: String?

    @Environment(\.colorScheme) private var colorScheme

    private struct Parameters: Equatable {
        let data: [String: Double]
        let colorScheme: ColorScheme
    }

    private var parameters: Parameters {
        Parameters(data: data, colorScheme: colorScheme)
    }
    
    var body: some View {
        ZStack {
            if let processedSVG {
                SVGWebView(htmlContent: processedSVG)
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
        let style = parameters.colorScheme == .dark ? configuration.darkStyle : configuration.lightStyle
        let processedSVGContent = await processSVG(
            svgContent: svgContent,
            data: parameters.data,
            colorAxis: style.colorAxis,
            strokeColor: style.strokeColor,
            fillColor: style.fillColor
        )
        guard !Task.isCancelled else { return }
        self.processedSVG = wrapSVGInHTML(processedSVGContent)
    }
    
    private func wrapSVGInHTML(_ svg: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=4.0, user-scalable=yes">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    overflow: hidden;
                }
                svg {
                    max-width: 100%;
                    max-height: 100%;
                    width: auto;
                    height: auto;
                }
            </style>
        </head>
        <body>
            \(svg)
        </body>
        </html>
        """
    }
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
    data: [String: Double],
    colorAxis: [Color],
    strokeColor: Color,
    fillColor: Color
) async -> String {
    // Find min and max values in the data
    let values = data.values
    let minValue = values.min() ?? 0
    let maxValue = values.max() ?? 1
    
    var processedContent = svgContent
    
    // Process each country in the data
    for (countryCode, value) in data {
        let normalizedValue = (value - minValue) / (maxValue - minValue)
        let color = interpolateColor(normalizedValue, colorAxis: colorAxis)
        
        // Replace fill color for paths with matching country codes
        processedContent = processCountryInSVG(processedContent, countryCode: countryCode, color: color)
    }
    
    // Update default fill color for countries without data
    processedContent = updateDefaultColors(processedContent, strokeColor: strokeColor, fillColor: fillColor)
    
    return processedContent
}

private func processCountryInSVG(_ svg: String, countryCode: String, color: Color) -> String {
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

private func updateDefaultColors(_ svg: String, strokeColor: Color, fillColor: Color) -> String {
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

private func interpolateColor(_ value: Double, colorAxis: [Color]) -> Color {
    // Ensure we have at least 2 colors
    guard colorAxis.count >= 2 else {
        return colorAxis.first ?? .blue
    }
    
    // Clamp value between 0 and 1
    let clampedValue = min(max(value, 0), 1)
    
    if colorAxis.count == 2 {
        // Simple interpolation between two colors
        return Color.interpolate(from: colorAxis[0], to: colorAxis[1], fraction: clampedValue)
    } else {
        // Multi-stop gradient interpolation
        let scaledValue = clampedValue * Double(colorAxis.count - 1)
        let lowerIndex = Int(scaledValue)
        let upperIndex = min(lowerIndex + 1, colorAxis.count - 1)
        let fraction = scaledValue - Double(lowerIndex)
        
        return Color.interpolate(
            from: colorAxis[lowerIndex],
            to: colorAxis[upperIndex],
            fraction: fraction
        )
    }
}

// MARK: - SVG WebView

private struct SVGWebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator

        webView.alpha = 0
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Force reload by clearing cache when color scheme changes
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Fade in when content is loaded
            UIView.animate(withDuration: 0.3, delay: 0.05, options: .curveEaseIn) {
                webView.alpha = 1
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
        configuration: .init(tintColor: Constants.Colors.blue)
    )
    .frame(height: 230)
    .background(Color(UIColor.systemBackground))
}
