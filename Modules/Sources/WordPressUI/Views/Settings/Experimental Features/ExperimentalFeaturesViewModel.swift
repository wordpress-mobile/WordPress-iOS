import SwiftUI

@MainActor
public class ExperimentalFeaturesViewModel: ObservableObject {
    public protocol DataProvider {
        func loadItems() async throws -> [Feature]
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
    public private(set) var items: [Feature] = []

    @Published
    public private(set) var isLoadingItems: Bool = true

    @Published
    public private(set) var error: Error? = nil

    private var dataProvider: DataProvider

    public init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    func loadItems() async {
        isLoadingItems = true
        defer { isLoadingItems = false }

        do {
            let items = try await dataProvider.loadItems()
            self.items = items
        } catch {
            self.error = error
        }
    }

    func binding(for item: Feature) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                self.dataProvider.value(for: item)
            },
            set: { newValue in
                self.objectWillChange.send()
                self.dataProvider.didChangeValue(for: item, to: newValue)
            }
        )
    }

    package static func withSampleData() -> ExperimentalFeaturesViewModel {
        let dataProvider = DefaultDataProvider(items: Feature.SampleData)
        return ExperimentalFeaturesViewModel(dataProvider: dataProvider)
    }
}
