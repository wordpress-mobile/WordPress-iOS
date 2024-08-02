import UIKit
import WordPressUI

class AcknowledgementsListViewModel: WordPressUI.AcknowledgementsListViewModel {
    private let service = AcknowledgementsService()

    override func loadItems() async throws -> [AcknowledgementItem] {
        try await service.fetchPackageData()
    }
}
