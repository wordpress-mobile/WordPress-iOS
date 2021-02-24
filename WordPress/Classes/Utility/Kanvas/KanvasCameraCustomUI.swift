import Foundation
import Kanvas

/// Contains custom colors and fonts for the KanvasCamera framework
public class KanvasCustomUI {

    public static let shared = KanvasCustomUI()

    private static let brightBlue = UIColor.muriel(color: MurielColor(name: .blue)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightPurple = UIColor.muriel(color: MurielColor(name: .purple)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightPink = UIColor.muriel(color: MurielColor(name: .pink)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightYellow = UIColor.muriel(color: MurielColor(name: .yellow)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightGreen = UIColor.muriel(color: MurielColor(name: .green)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightRed = UIColor.muriel(color: MurielColor(name: .red)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let brightOrange = UIColor.muriel(color: MurielColor(name: .orange)).color(for: UITraitCollection(userInterfaceStyle: .dark))
    private static let white = UIColor.white

    static private var firstPrimary: UIColor {
        return KanvasCustomUI.primaryColors.first ?? UIColor.blue
    }

    static private var lastPrimary: UIColor {
        return KanvasCustomUI.primaryColors.last ?? UIColor.green
    }

    private let pickerColors: [UIColor] = [KanvasCustomUI.firstPrimary] + KanvasCustomUI.primaryColors + [KanvasCustomUI.lastPrimary]

    private let segmentColors: [UIColor] = KanvasCustomUI.primaryColors + KanvasCustomUI.primaryColors + [KanvasCustomUI.firstPrimary]

    static private let primaryColors: [UIColor] = [.blue,
                                            .purple,
                                            .magenta,
                                            .red,
                                            .yellow,
                                            .green]

    private let backgroundColorCollection: [UIColor] = KanvasCustomUI.primaryColors

    private let mangaColor: UIColor = brightPink
    private let toonColor: UIColor = brightOrange

    private let selectedColor = brightBlue // ColorPickerController:29
    private let black25 = UIColor(white: 0, alpha: 0.25)

    func cameraColors() -> KanvasColors {
        let firstPrimary = KanvasCustomUI.primaryColors.first ?? .blue
        return KanvasColors(
            drawingDefaultColor: firstPrimary,
            colorPickerColors: pickerColors,
            selectedPickerColor: selectedColor,
            timeSegmentColors: segmentColors,
            backgroundColors: backgroundColorCollection,
            strokeColor: firstPrimary,
            sliderActiveColor: firstPrimary,
            sliderOuterCircleColor: firstPrimary,
            trimBackgroundColor: firstPrimary,
            trashColor: Self.brightRed,
            tooltipBackgroundColor: .systemRed,
            closeButtonColor: black25,
            primaryButtonBackgroundColor: Self.brightRed,
            permissionsButtonColor: Self.brightBlue,
            permissionsButtonAcceptedBackgroundColor: UIColor.muriel(color: MurielColor(name: .green, shade: .shade20)),
            overlayColor: UIColor.muriel(color: MurielColor.gray),
            filterColors: [
                .manga: mangaColor,
                .toon: toonColor,
            ])
    }

    private static let cameraPermissions = KanvasFonts.CameraPermissions(titleFont: UIFont.systemFont(ofSize: 26, weight: .medium), descriptionFont: UIFont.systemFont(ofSize: 16), buttonFont: UIFont.systemFont(ofSize: 16, weight: .medium))
    private static let drawer = KanvasFonts.Drawer(textSelectedFont: UIFont.systemFont(ofSize: 14, weight: .medium), textUnselectedFont: UIFont.systemFont(ofSize: 14))

    func cameraFonts() -> KanvasFonts {
        let paddingAdjustment: (UIFont) -> KanvasFonts.Padding? = { font in
            if font == UIFont.systemFont(ofSize: font.pointSize) {
                return KanvasFonts.Padding(topMargin: 8.0,
                        leftMargin: 5.7,
                        extraVerticalPadding: 0.125 * font.pointSize,
                        extraHorizontalPadding: 0)
            }
            else {
                return nil
            }
        }
        let editorFonts: [UIFont] = [.libreBaskerville(fontSize: 20), .nunitoBold(fontSize: 24), .pacifico(fontSize: 24), .shrikhand(fontSize: 22), .spaceMonoBold(fontSize: 20), .oswaldUpper(fontSize: 22)]
        return KanvasFonts(permissions: Self.cameraPermissions,
                                 drawer: Self.drawer,
                                 editorFonts: editorFonts,
                                 optionSelectorCellFont: UIFont.systemFont(ofSize: 16, weight: .medium),
                                 mediaClipsFont: UIFont.systemFont(ofSize: 9.5),
                                 mediaClipsSmallFont: UIFont.systemFont(ofSize: 8),
                                 modeButtonFont: UIFont.systemFont(ofSize: 18.5),
                                 speedLabelFont: UIFont.systemFont(ofSize: 16, weight: .medium),
                                 timeIndicatorFont: UIFont.systemFont(ofSize: 16, weight: .medium),
                                 colorSelectorTooltipFont:
                                    UIFont.systemFont(ofSize: 14),
                                 modeSelectorTooltipFont: UIFont.systemFont(ofSize: 15),
                                 postLabelFont: UIFont.systemFont(ofSize: 14, weight: .medium),
                                 gifMakerRevertButtonFont: UIFont.systemFont(ofSize: 15, weight: .bold),
                                 paddingAdjustment: paddingAdjustment
                                 )
    }

    func cameraImages() -> KanvasImages {
        return KanvasImages(confirmImage: UIImage(named: "stories-confirm-button"), editorConfirmImage: UIImage(named: "stories-confirm-button"), nextImage: UIImage(named: "stories-next-button"))
    }
}

enum CustomKanvasFonts: CaseIterable {
    case libreBaskerville
    case nunitoBold
    case pacifico
    case oswaldUpper
    case shrikhand
    case spaceMonoBold

    struct Shadow {
        let radius: CGFloat
        let offset: CGPoint
        let color: UIColor
    }

    var name: String {
        switch self {
        case .libreBaskerville:
            return "LibreBaskerville-Regular"
        case .nunitoBold:
            return "Nunito-Bold"
        case .pacifico:
            return "Pacifico-Regular"
        case .oswaldUpper:
            return "Oswald-Regular"
        case .shrikhand:
            return "Shrikhand-Regular"
        case .spaceMonoBold:
            return "SpaceMono-Bold"
        }
    }

    var size: Int {
        switch self {
        case .libreBaskerville:
            return 20
        case .nunitoBold:
            return 24
        case .pacifico:
            return 24
        case .oswaldUpper:
            return 22
        case .shrikhand:
            return 22
        case .spaceMonoBold:
            return 20
        }
    }

    var shadow: Shadow? {
        switch self {
        case .libreBaskerville:
            return nil
        case .nunitoBold:
            return Shadow(radius: 1, offset: CGPoint(x: 0, y: 2), color: UIColor.black.withAlphaComponent(75))
        case .pacifico:
            return Shadow(radius: 5, offset: .zero, color: UIColor.white.withAlphaComponent(50))
        case .oswaldUpper:
            return nil
        case .shrikhand:
            return Shadow(radius: 1, offset: CGPoint(x: 1, y: 2), color: UIColor.black.withAlphaComponent(75))
        case .spaceMonoBold:
            return nil
        }
    }
}

extension UIFont {

    static func libreBaskerville(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "LibreBaskerville-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    static func nunitoBold(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "Nunito-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    static func pacifico(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "Pacifico-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    static func oswaldUpper(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "Oswald-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    static func shrikhand(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "Shrikhand-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    static func spaceMonoBold(fontSize: CGFloat) -> UIFont {
        let font = UIFont(name: "SpaceMono-Bold", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize, weight: .medium)
        return UIFontMetrics.default.scaledFont(for: font)
    }

    @objc func fontByAddingSymbolicTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let modifiedTraits = fontDescriptor.symbolicTraits.union(trait)
        guard let modifiedDescriptor = fontDescriptor.withSymbolicTraits(modifiedTraits) else {
            assertionFailure("Unable to created modified font descriptor by adding a symbolic trait.")
            return self
        }
        return UIFont(descriptor: modifiedDescriptor, size: pointSize)
    }
}
