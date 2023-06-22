import Foundation
import UIKit
import WordPressKit

final class BlazeCampaignStatusView: UIView {
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

    func configure(with viewModel: BlazeCampaignStatusViewModel) {
        self.isHidden = viewModel.isHidden
        self.titleLabel.text = viewModel.title.uppercased()
        self.titleLabel.textColor = viewModel.textColor
        self.backgroundColor = viewModel.backgroundColor
        self.layer.masksToBounds = true
        self.layer.cornerRadius = Constants.cornerRadius
    }
}

private extension BlazeCampaignStatusView {
    enum Constants {
        static let titleInsets = UIEdgeInsets(top: 4, left: 4, bottom: 3, right: 4)
        static let cornerRadius: CGFloat = 4
    }
}

struct BlazeCampaignStatusViewModel {
    let isHidden: Bool
    let title: String
    let textColor: UIColor
    let backgroundColor: UIColor

    init(campaign: BlazeCampaign) {
        self.init(status: campaign.uiStatus)
    }

    init(status: BlazeCampaign.Status) {
        self.isHidden = status == .unknown
        self.title = status.localizedTitle

        switch status {
        case .created, .processing, .scheduled, .canceled:
            self.textColor = UIColor(
                light: UIColor(fromHex: 0x4F3500),
                dark: UIColor(fromHex: 0xDEB100)
            )
            self.backgroundColor = UIColor(
                light: UIColor(fromHex: 0xF5E6B3),
                dark: UIColor(fromHex: 0x332200)
            )
        case .rejected:
            self.textColor = UIColor(
                light: UIColor(fromHex: 0x8A2424),
                dark: UIColor(fromHex: 0xF86368)
            )
            self.backgroundColor = UIColor(
                light: UIColor(fromHex: 0xFACFD2),
                dark: UIColor(fromHex: 0x451313)
            )
        case .active, .approved:
            self.textColor = UIColor(
                light: UIColor(fromHex: 0x00450C),
                dark: UIColor(fromHex: 0x00BA37)
            )
            self.backgroundColor = UIColor(
                light: UIColor(fromHex: 0xB8E6BF),
                dark: UIColor(fromHex: 0x003008)
            )
        case .finished:
            self.textColor = UIColor(
                light: UIColor(fromHex: 0x02395C),
                dark: UIColor(fromHex: 0x399CE3)
            )
            self.backgroundColor = UIColor(
                light: UIColor(fromHex: 0xBBE0FA),
                dark: UIColor(fromHex: 0x01283D)
            )
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
            return NSLocalizedString("blazeCampaign.status.scheduled", value: "Scheduled", comment: "Short status description")
        case .created:
            return NSLocalizedString("blazeCampaign.status.created", value: "Created", comment: "Short status description")
        case .approved:
            return NSLocalizedString("blazeCampaign.status.approved", value: "Approved", comment: "Short status description")
        case .processing:
            return NSLocalizedString("blazeCampaign.status.inmoderation", value: "In Moderation", comment: "Short status description")
        case .rejected:
            return NSLocalizedString("blazeCampaign.status.rejected", value: "Rejected", comment: "Short status description")
        case .active:
            return NSLocalizedString("blazeCampaign.status.active", value: "Active", comment: "Short status description")
        case .canceled:
            return NSLocalizedString("blazeCampaign.status.canceled", value: "Canceled", comment: "Short status description")
        case .finished:
            return NSLocalizedString("blazeCampaign.status.completed", value: "Completed", comment: "Short status description")
        case .unknown:
            return "–"
        }
    }
}
