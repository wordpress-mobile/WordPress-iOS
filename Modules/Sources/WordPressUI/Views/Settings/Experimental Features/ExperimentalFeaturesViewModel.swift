import SwiftUI

public class ExperimentalFeaturesViewModel: ObservableObject {
    public protocol DataProvider {
        func loadItems() throws -> [Feature]
        func value(for: Feature) -> Bool
        func didChangeValue(for feature: Feature, to newValue: Bool)
    }

    package class DefaultDataProvider: DataProvider {

        let items: [Feature]

        var values = [String: Bool]()

        init(items: [Feature]) {
            self.items = items
        }

        package func loadItems() throws -> [Feature] {
            return items
        }

        package func value(for feature: Feature) -> Bool {
            if let value = values[feature.id] {
                return value
            }

            values[feature.id] = false
            return value(for: feature)
        }

        package func didChangeValue(for feature: Feature, to newValue: Bool) {
            values[feature.id] = newValue
        }
    }

    @Published
    public var items: [Feature] = []

    @Published
    public var isLoadingItems: Bool = true

    @Published
    public var error: Error? = nil

    var dataProvider: DataProvider

    init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    @MainActor
    func loadItems() async {
        do {
            let items = try dataProvider.loadItems()
            self.items = items
            self.isLoadingItems = false
        } catch {
            self.error = error
            self.isLoadingItems = false
        }
    }

    package static func withSampleData() -> ExperimentalFeaturesViewModel {
        let dataProvider = DefaultDataProvider(items: Feature.SampleData)
        return ExperimentalFeaturesViewModel(dataProvider: dataProvider)
    }
}
