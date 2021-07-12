import Foundation
import WordPressKit
import Gutenberg

extension BlockEditorSettings: GutenbergEditorSettings {
    public var colors: [[String: String]]? {
        elementsByType(.color)
    }

    public var gradients: [[String: String]]? {
        elementsByType(.gradient)
    }

    public var galleryRefactor: Bool {
        return experimentalFeature(.galleryRefactor)
    }

    private func elementsByType(_ type: BlockEditorSettingElementTypes) -> [[String: String]]? {
        return elements?.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.order >= rhs.order
        }).compactMap({ (element) -> [String: String]? in
            guard element.type == type.rawValue else { return nil }
            return element.rawRepresentation
        })
    }

    private func experimentalFeature(_ feature: BlockEditorExperimentalFeatureKeys) -> Bool {
        guard let experimentalFeature = elements?.first(where: { (element) -> Bool in
            guard element.type == BlockEditorSettingElementTypes.experimentalFeatures.rawValue else { return false }
            return element.slug == feature.rawValue
        }) else { return false }

        return Bool(experimentalFeature.value) ?? false
    }
}

extension BlockEditorSettings {
    convenience init?(editorTheme: RemoteEditorTheme, context: NSManagedObjectContext) {
        self.init(context: context)
        self.isFSETheme = false
        self.lastUpdated = Date()
        self.checksum = editorTheme.checksum

        var parsedElements = Set<BlockEditorSettingElement>()
        if let themeSupport = editorTheme.themeSupport {
            themeSupport.colors?.enumerated().forEach({ (index, color) in
                parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: color, type: .color, order: index, context: context))
            })

            themeSupport.gradients?.enumerated().forEach({ (index, gradient) in
                parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: gradient, type: .gradient, order: index, context: context))
            })
        }

        self.elements = parsedElements
    }

    convenience init?(remoteSettings: RemoteBlockEditorSettings, context: NSManagedObjectContext) {
        self.init(context: context)
        self.isFSETheme = remoteSettings.isFSETheme
        self.lastUpdated = Date()
        self.checksum = remoteSettings.checksum
        self.rawStyles = remoteSettings.rawStyles
        self.rawFeatures = remoteSettings.rawFeatures

        var parsedElements = Set<BlockEditorSettingElement>()

        remoteSettings.colors?.enumerated().forEach({ (index, color) in
            parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: color, type: .color, order: index, context: context))
        })

        remoteSettings.gradients?.enumerated().forEach({ (index, gradient) in
            parsedElements.insert(BlockEditorSettingElement(fromRawRepresentation: gradient, type: .gradient, order: index, context: context))
        })

        // Experimental Features
        let galleryKey = BlockEditorExperimentalFeatureKeys.galleryRefactor.rawValue
        let galleryRefactor = BlockEditorSettingElement(name: galleryKey,
                                                         value: "\(remoteSettings.galleryRefactor)",
                                                         slug: galleryKey,
                                                         type: .experimentalFeatures,
                                                         order: 0,
                                                         context: context)
        parsedElements.insert(galleryRefactor)

        self.elements = parsedElements
    }
}
