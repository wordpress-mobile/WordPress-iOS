import Foundation


public class NoteSettingsSubtitleTableViewCell : UITableViewCell
{
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewSmallSubtitleCell(self)
    }
}
