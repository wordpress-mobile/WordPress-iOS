import UIKit

class VideoResolutionTableViewController: UITableViewController {
    var selectedResolutionIndex = 0;
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedResolutionIndex = MediaSettings().maxVideoSizeSetting.intValue - 1
        tableView.cellForRow(at: IndexPath(row: selectedResolutionIndex, section: 0))?.accessoryType = .checkmark
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        deselectOldRow()
        selectAndSaveCurrentRow(at: indexPath)
    }
    
    func deselectOldRow() {
        let oldPath = IndexPath(row: selectedResolutionIndex, section: 0)
        let oldCell = tableView.cellForRow(at: oldPath)
        oldCell?.accessoryType = .none
    }
    
    func selectAndSaveCurrentRow(at indexPath: IndexPath) {
        let currentCell = tableView.cellForRow(at: indexPath)
        currentCell?.accessoryType = .checkmark
        selectedResolutionIndex = indexPath.row
        MediaSettings().maxVideoSizeSetting = resolutionOfIndexPath(indexPath: indexPath)
    }
    
    func resolutionOfIndexPath(indexPath: IndexPath) -> MediaSettings.VideoResolution {
        switch indexPath.row {
        case 0:
            return MediaSettings.VideoResolution.size640x480
        case 1:
            return MediaSettings.VideoResolution.size1280x720
        case 2:
            return MediaSettings.VideoResolution.size1920x1080
        case 3:
            return MediaSettings.VideoResolution.size3840x2160
        case 4:
            return MediaSettings.VideoResolution.sizeOriginal
        default:
            return MediaSettings.VideoResolution.sizeOriginal
        }
    }
}
