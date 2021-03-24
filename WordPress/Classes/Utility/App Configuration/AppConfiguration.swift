import Foundation

@objc class AppConfiguration: NSObject, TargetConfiguration {
    @objc static let isJetpack: Bool = false
}

extension AppConfiguration: TargetColorConfiguration {
    static let accent = MurielColor(name: .pink)
    static let brand = MurielColor(name: .wordPressBlue)
    static let divider = MurielColor(name: .gray, shade: .shade10)
    static let error = MurielColor(name: .red)
    static let gray = MurielColor(name: .gray)
    static let primary = MurielColor(name: .blue)
    static let success = MurielColor(name: .green)
    static let text = MurielColor(name: .gray, shade: .shade80)
    static let textSubtle = MurielColor(name: .gray, shade: .shade50)
    static let warning = MurielColor(name: .yellow)
    static let jetpackGreen = MurielColor(name: .jetpackGreen)
}
