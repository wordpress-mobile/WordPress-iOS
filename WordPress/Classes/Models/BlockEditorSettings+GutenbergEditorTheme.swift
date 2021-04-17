import Foundation
import Gutenberg

extension BlockEditorSettings: GutenbergEditorTheme {
    public var colors: [[String: String]]? {
        elementsByType(.color)
    }

    public var gradients: [[String: String]]? {
        elementsByType(.gradient)
    }

    private func elementsByType(_ type: BlockEditorSettingElementTypes) -> [[String: String]]? {
        return elements?.compactMap({ (element) -> [String: String]? in
            guard element.type == type.rawValue else { return nil }
            return element.rawRepresentation
        })
    }
}

extension BlockEditorSettings {
    convenience init?(editorTheme: EditorTheme, context: NSManagedObjectContext) {
        self.init(context: context)
        self.lastUpdated = Date()
        self.checksum = editorTheme.checksum

        var parsedElements = Set<BlockEditorSettingElement>()
        if let themeSupport = editorTheme.themeSupport {
            themeSupport.colors?.forEach({ (color) in
                parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: color, type: .color, context: context))
            })

            themeSupport.gradients?.forEach({ (gradient) in
                parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: gradient, type: .gradient, context: context))
            })
        }

        self.elements = parsedElements
    }
}
