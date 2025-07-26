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
            loadAndProcessSVG()
        }
        .onChange(of: data) { _ in
            if svgContent != nil {
                processSVG()
            }
        }
    }
    
    private func loadAndProcessSVG() {
        print("InteractiveMapView: Loading SVG resource: \(svgResourceName)")
        
        // Try multiple approaches to load the SVG
        if let svgPath = Bundle.module.path(forResource: svgResourceName, ofType: "svg"),
           let content = try? String(contentsOfFile: svgPath) {
            print("InteractiveMapView: Successfully loaded SVG from path, content length: \(content.count)")
            svgContent = content
            processSVG()
            return
        }
        
        // Try URL approach
        if let url = Bundle.module.url(forResource: svgResourceName, withExtension: "svg"),
           let content = try? String(contentsOf: url) {
            print("InteractiveMapView: Successfully loaded SVG from URL, content length: \(content.count)")
            svgContent = content
            processSVG()
            return
        }
    }
    
    private func processSVG() {
        guard let svgContent = svgContent else { return }
        
        print("InteractiveMapView: Processing SVG with data for \(data.count) countries")
        
        // Find min and max values in the data
        let values = data.values
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        
        print("InteractiveMapView: Data range: \(minValue) - \(maxValue)")
        
        var processedContent = svgContent
        
        // Process each country in the data
        for (countryCode, value) in data {
            let normalizedValue = (value - minValue) / (maxValue - minValue)
            let color = interpolateColor(normalizedValue)
            
            // Replace fill color for paths with matching country codes
            // SVG paths typically have id or class attributes with country codes
            processedContent = processCountryInSVG(processedContent, countryCode: countryCode, color: color)
        }
        
        // Update default fill color for countries without data
        processedContent = updateDefaultColors(processedContent)
        
        print("InteractiveMapView: Finished processing SVG, final length: \(processedContent.count)")
        
        self.processedSVG = processedContent
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
    
    private func updateDefaultColors(_ svg: String) -> String {
        var result = svg
        
        // First, update the CSS class that defines default colors
        let fillHex = fillColor.toHex()
        let strokeHex = strokeColor.toHex()
        
        // Replace the .st0 class definition in the style tag
        result = result.replacingOccurrences(
            of: "\\.st0\\{[^}]*\\}",
            with: ".st0{fill:\(fillHex);stroke:\(strokeHex);stroke-width:0.5;}",
            options: .regularExpression
        )
        
        return result
    }
    
    private func interpolateColor(_ value: Double) -> Color {
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
    
    private func wrapSVGInHTML(_ svg: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
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
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        
        print("InteractiveMapView: Created WKWebView")
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        print("InteractiveMapView: Loading HTML content, length: \(htmlContent.count)")
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("InteractiveMapView: WebView finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("InteractiveMapView: WebView failed to load: \(error)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("InteractiveMapView: WebView failed provisional navigation: \(error)")
        }
    }
}

// MARK: - Color Extensions

private extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return String(format: "#%02X%02X%02X", 
                      Int(red * 255), 
                      Int(green * 255), 
                      Int(blue * 255))
    }
    
    static func interpolate(from: Color, to: Color, fraction: Double) -> Color {
        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)
        
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        fromUIColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        toUIColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * CGFloat(fraction)
        let g = g1 + (g2 - g1) * CGFloat(fraction)
        let b = b1 + (b2 - b1) * CGFloat(fraction)
        let a = a1 + (a2 - a1) * CGFloat(fraction)
        
        return Color(UIColor(red: r, green: g, blue: b, alpha: a))
    }
}


// MARK: - Preview

#Preview("Interactive Map") {
    VStack(spacing: 20) {
        // Full featured map
        VStack(alignment: .leading, spacing: 8) {
            Text("Countries by Views")
                .font(.headline)
            
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
                    Constants.Colors.blue.opacity(0.1),
                    Constants.Colors.blue
                ],
                strokeColor: Color(UIColor.secondarySystemGroupedBackground),
                fillColor: Color(UIColor(light: .systemGray5, dark: .systemGray6))
            )
            .frame(height: 200)
            .cornerRadius(8)
        }
        
        // Different color scheme
        VStack(alignment: .leading, spacing: 8) {
            Text("Countries by Downloads")
                .font(.headline)
            
            InteractiveMapView(
                svgResourceName: "world-map",
                data: [
                    "US": 5000,
                    "GB": 2200,
                    "DE": 1800,
                    "CA": 1500,
                    "AU": 1200,
                    "FR": 1000,
                    "JP": 900,
                    "NL": 600,
                    "CH": 400,
                    "SE": 350
                ],
                colorAxis: [
                    Constants.Colors.green.opacity(0.2),
                    Constants.Colors.green.opacity(0.6),
                    Constants.Colors.green
                ],
                strokeColor: Color(UIColor.systemGray4),
                fillColor: Color(UIColor.systemGray6)
            )
            .frame(height: 200)
            .cornerRadius(8)
        }
        
        // Minimal data
        VStack(alignment: .leading, spacing: 8) {
            Text("Top 3 Countries")
                .font(.headline)
            
            InteractiveMapView(
                svgResourceName: "world-map",
                data: [
                    "US": 100,
                    "GB": 50,
                    "CA": 25
                ],
                colorAxis: [
                    Constants.Colors.purple.opacity(0.3),
                    Constants.Colors.purple
                ],
                strokeColor: Color(UIColor.separator),
                fillColor: Color(UIColor.tertiarySystemFill)
            )
            .frame(height: 200)
            .cornerRadius(8)
        }
    }
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}

#Preview("Map with Countries Container") {
    CountriesMapContainer(
        data: CountriesMapData(locations: [
            TopListData.Location(
                country: "United States",
                flag: "🇺🇸",
                countryCode: "US",
                metrics: SiteMetricsSet(views: 10000)
            ),
            TopListData.Location(
                country: "United Kingdom",
                flag: "🇬🇧",
                countryCode: "GB",
                metrics: SiteMetricsSet(views: 4000)
            ),
            TopListData.Location(
                country: "Canada",
                flag: "🇨🇦",
                countryCode: "CA",
                metrics: SiteMetricsSet(views: 2800)
            ),
            TopListData.Location(
                country: "Germany",
                flag: "🇩🇪",
                countryCode: "DE",
                metrics: SiteMetricsSet(views: 2000)
            ),
            TopListData.Location(
                country: "Australia",
                flag: "🇦🇺",
                countryCode: "AU",
                metrics: SiteMetricsSet(views: 1600)
            ),
            TopListData.Location(
                country: "France",
                flag: "🇫🇷",
                countryCode: "FR",
                metrics: SiteMetricsSet(views: 1400)
            ),
            TopListData.Location(
                country: "Japan",
                flag: "🇯🇵",
                countryCode: "JP",
                metrics: SiteMetricsSet(views: 1100)
            ),
            TopListData.Location(
                country: "Netherlands",
                flag: "🇳🇱",
                countryCode: "NL",
                metrics: SiteMetricsSet(views: 800)
            )
        ]),
        primaryColor: Constants.Colors.blue
    )
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
