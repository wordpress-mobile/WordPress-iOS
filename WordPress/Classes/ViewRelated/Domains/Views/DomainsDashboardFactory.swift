import Foundation
import SwiftUI

struct DomainsDashboardFactory {
    static func makeDomainsDashboardViewController(blog: Blog) -> UIViewController {
        let viewController = UIHostingController(rootView: DomainsDashboardView(blog: blog))
        viewController.extendedLayoutIncludesOpaqueBars = true
        return viewController
    }
}
