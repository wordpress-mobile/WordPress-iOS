import UIKit

class JetpackActivityLogViewController: ActivityListViewController {
    override init(site: JetpackSiteRef, store: ActivityStore, isFreeWPCom: Bool = false) {
        let activityListConfiguration = ActivityListConfiguration(
            title: NSLocalizedString("Activity", comment: "Title for the activity list")
        )

        super.init(site: site, store: store, configuration: activityListConfiguration, isFreeWPCom: isFreeWPCom)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
