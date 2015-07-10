import Foundation


public class NoteSettingsSubtitleTableViewCell : WPTableViewCell
{
    // MARK: - UIView Methods
    public override func awakeFromNib() {
        accessoryType = .DisclosureIndicator
        WPStyleGuide.configureTableViewSmallSubtitleCell(self)
    }
}
