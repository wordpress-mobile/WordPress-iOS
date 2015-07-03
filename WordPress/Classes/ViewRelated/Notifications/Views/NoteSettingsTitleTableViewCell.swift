import Foundation


public class NoteSettingsTitleTableViewCell : UITableViewCell
{
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewCell(self)
    }
}
