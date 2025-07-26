import SwiftUI
import WebKit

/// A native SwiftUI implementation of an interactive map view that displays SVG maps
/// with data-driven coloring of regions.
struct InteractiveMapView: View {
    let svgResourceName: String
    let data: [String: Double]
    let colorAxis: [Color]
    let strokeColor: Color
    let fillColor: Color
    
    @State private var svgContent: String?
    @State private var processedSVG: String?
    
    var body: some View {
        ZStack {
            if let processedSVG = processedSVG {
                // Use WKWebView to render the SVG as it provides the best SVG support
                SVGWebView(htmlContent: wrapSVGInHTML(processedSVG))
                    .background(Color.clear)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                if svgContent == nil {
                    svgContent = await loadSVG(resourceName: svgResourceName)
                }
                await updateMap()
            }
        }
        .onChange(of: data) { _ in
            Task {
                await updateMap()
            }
        }
    }
    
    @MainActor
    private func updateMap() async {
        guard let svgContent = svgContent else { return }
        
        // Process SVG with current data
        let processed = await processSVG(
            svgContent: svgContent,
            data: data,
            colorAxis: colorAxis,
            strokeColor: strokeColor,
            fillColor: fillColor
        )
        
        // Update UI
        self.processedSVG = processed
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
    
    // Try URL approach
    if let url = Bundle.module.url(forResource: resourceName, withExtension: "svg"),
       let content = try? String(contentsOf: url) {
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
        svgResourceName: "world-map",
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
        colorAxis: [
            Constants.Colors.blue.lightened(by: 0.8),
            Constants.Colors.blue
        ],
        strokeColor: Color(UIColor(light: .systemGray2, dark: .systemGray2)),
        fillColor: Color(UIColor(light: .systemGray6, dark: .red))
    )
    .frame(height: 230)
    .background(Color(UIColor.systemBackground))
}
