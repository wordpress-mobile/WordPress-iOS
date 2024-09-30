import Foundation

public struct Feature: Identifiable {
    public let name: String
    public let key: String

    public var id: String { key }

    public init(name: String, key: String) {
        self.name = name
        self.key = key
    }

    package static let SampleData: [Feature]  = [
        Feature(name: "Stratify Ground Layers", key: "01"),
        Feature(name: "Reticulate Splines", key: "02"),
        Feature(name: "Obfuscate Quigley Matrix", key: "03"),
    ]
}
