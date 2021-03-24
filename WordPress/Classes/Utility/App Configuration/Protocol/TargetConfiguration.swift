import Foundation

protocol TargetConfiguration {
    static var isJetpack: Bool { get }
}

protocol TargetColorConfiguration {
    static var accent: MurielColor { get }
    static var brand: MurielColor { get }
    static var divider: MurielColor { get }
    static var error: MurielColor { get }
    static var gray: MurielColor { get }
    static var primary: MurielColor { get }
    static var success: MurielColor { get }
    static var text: MurielColor { get }
    static var textSubtle: MurielColor { get }
    static var warning: MurielColor { get }
    static var jetpackGreen: MurielColor { get }
}
