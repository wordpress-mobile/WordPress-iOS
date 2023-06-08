import Foundation
import UIKit
import WordPressKit

final class DashboardBlazeCampaignStatusView: UIView {
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.font = WPStyleGuide.fontForTextStyle(.caption2, fontWeight: .semibold)

        addSubview(titleLabel)
        pinSubviewToAllEdges(titleLabel, insets: Constants.titleInsets)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: DashboardBlazeCampaignViewStatusViewModel) {
        self.isHidden = viewModel.isHidden
        self.titleLabel.text = viewModel.title.uppercased()
        self.titleLabel.textColor = viewModel.textColor
        self.backgroundColor = viewModel.backgroundColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
    }
}

private extension DashboardBlazeCampaignStatusView {
    enum Constants {
        static let titleInsets = UIEdgeInsets(top: 4, left: 4, bottom: 3, right: 4)
        static let cornerRadius: CGFloat = 4
    }
}

struct DashboardBlazeCampaignViewStatusViewModel {
    let isHidden: Bool
    let title: String
    let textColor: UIColor
    let backgroundColor: UIColor

    init(status: BlazeCampaign.Status) {
        self.isHidden = status == .unknown
        self.title = status.localizedTitle

        switch status {
        case .created, .processing, .scheduled, .canceled:
            self.textColor = UIColor(fromHex: 0x4F3500)
            self.backgroundColor = UIColor(fromHex: 0xF5E6B3)
        case .rejected:
            self.textColor = UIColor(fromHex: 0x8A2424)
            self.backgroundColor = UIColor(fromHex: 0xFACFD2)
        case .active, .approved:
            self.textColor = UIColor(fromHex: 0x00450C)
            self.backgroundColor = UIColor(fromHex: 0xB8E6BF)
        case .finished:
            self.textColor = UIColor(fromHex: 0x02395C)
            self.backgroundColor = UIColor(fromHex: 0xBBE0FA)
        case .unknown:
            self.textColor = .label
            self.backgroundColor = .secondarySystemBackground
        }
    }
}

extension BlazeCampaign.Status {
    var localizedTitle: String {
        switch self {
        case .scheduled:
            return NSLocalizedString("blazeCampaign.status.finished", value: "Scheduled", comment: "Short status description")
        case .created:
            return NSLocalizedString("blazeCampaign.status.finished", value: "Created", comment: "Short status description")
        case .approved:
            return NSLocalizedString("blazeCampaign.status.finished", value: "Approved", comment: "Short status description")
        case .processing:
            return NSLocalizedString("blazeCampaign.status.finished", value: "In Moderation", comment: "Short status description")
        case .rejected:
            return NSLocalizedString("blazeCampaign.status.rejected", value: "Rejected", comment: "Short status description")
        case .active:
            return NSLocalizedString("blazeCampaign.status.active", value: "Active", comment: "Short status description")
        case .canceled:
            return NSLocalizedString("blazeCampaign.status.finished", value: "Cancelled", comment: "Short status description")
        case .finished:
            return NSLocalizedString("blazeCampaign.status.finished", value: "Completed", comment: "Short status description")
        case .unknown:
            return "–"
        }
    }
}
