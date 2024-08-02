import SwiftUI

public class AcknowledgementsListViewModel: ObservableObject {

    public protocol DataProvider: Actor {
        func loadItems() throws -> [AcknowledgementItem]
    }

    package actor DefaultAcknowledgementsDataProvider: DataProvider {
        let items: [AcknowledgementItem]

        init(items: [AcknowledgementItem]) {
            self.items = items
        }

        package func loadItems() throws -> [AcknowledgementItem] {
            return items
        }
    }

    @Published
    public var items: [AcknowledgementItem] = []

    @Published
    public var isLoadingItems: Bool = true

    @Published
    public var error: Error? = nil

    private let dataProvider: DataProvider

    @MainActor
    func loadItems() async {
        do {
            let items = try await dataProvider.loadItems()
            self.items = items
            self.isLoadingItems = false
        } catch {
            self.error = error
            self.isLoadingItems = false
        }
    }

    public init(dataProvider: DataProvider) {
        self.dataProvider = dataProvider
    }

    package static func withSampleData() -> AcknowledgementsListViewModel {
        let dataProvider = DefaultAcknowledgementsDataProvider(items: AcknowledgementItem.sampleData)
        return AcknowledgementsListViewModel(dataProvider: dataProvider)
    }
}
