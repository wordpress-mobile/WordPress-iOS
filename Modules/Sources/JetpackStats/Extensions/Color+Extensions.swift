import SwiftUI

extension Color {
    /// Converts a Color to its hex string representation
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
    
    /// Interpolates between two colors
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
    
    /// Lightens the color by mixing it with white
    func lightened(by percentage: Double) -> Color {
        Color.interpolate(from: self, to: .white, fraction: percentage)
    }
}