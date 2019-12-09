import UIKit
import NotificationCenter

    // MARK: - Properties

    private var statsValues: ThisWeekWidgetStats?

class ThisWeekViewController: UIViewController, NCWidgetProviding {


    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveData()
    }

}
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
// MARK: - Private Extension

private extension ThisWeekViewController {

    // MARK: - Data Management

    func loadSavedData() {
        statsValues = ThisWeekWidgetStats.loadSavedData()
    }

    func saveData() {
        statsValues?.saveData()
    }

}
