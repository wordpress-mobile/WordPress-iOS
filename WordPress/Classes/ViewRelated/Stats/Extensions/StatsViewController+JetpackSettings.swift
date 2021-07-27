import Foundation
import UIKit

extension StatsViewController {

    @objc func activateStatsModule(success: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        guard let context = blog.settings?.managedObjectContext else {
            return
        }

        let service = BlogJetpackSettingsService(managedObjectContext: context)

        service.updateJetpackModuleActiveSettingForBlog(blog,
                                                        module: Constants.statsModule,
                                                        active: true,
                                                        success: success,
                                                        failure: failure)

    }

    private enum Constants {
        static let statsModule = "stats"
    }

}
