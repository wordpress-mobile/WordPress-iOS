import SwiftUI

open class AcknowledgementsListViewModel: ObservableObject {

    @Published
    public var items: [AcknowledgementItem]

    @Published
    public var isLoadingItems: Bool

    @Published
    public var error: Error?

    private var taskHandle: Task<Void, Error>?

    open func loadItems() async throws -> [AcknowledgementItem] {
        abort() // This should never run – subclass this ViewModel and override this method
    }

    public init() {
        self.items = []
        self.isLoadingItems = true
    }

    private init(items: [AcknowledgementItem]) {
        self.items = items
        self.isLoadingItems = false
    }

    @MainActor
    func onAppear() {
        self.taskHandle = Task {
            do {
                let items = try await self.loadItems()
                await MainActor.run {
                    self.items = items
                    self.isLoadingItems = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }

    @MainActor
    func onDisappear() {
        self.taskHandle?.cancel()
    }

    package static func withSampleData() -> AcknowledgementsListViewModel {
        AcknowledgementsListViewModel(items: AcknowledgementItem.sampleData)
    }
}
