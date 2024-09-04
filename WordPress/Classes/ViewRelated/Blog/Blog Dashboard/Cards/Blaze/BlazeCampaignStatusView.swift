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
        case .created, .processing:
            self.textColor = UIColor(
                light: AppColor.yellow(.shade80),
                dark: AppColor.yellow(.shade10)
            )
            self.backgroundColor = UIColor(
                light: AppColor.yellow(.shade5),
                dark: AppColor.yellow(.shade90)
            )
        case .canceled, .rejected:
            self.textColor = UIColor(
                light: AppColor.red(.shade70),
                dark: AppColor.red(.shade10)
            )
            self.backgroundColor = UIColor(
                light: AppColor.red(.shade5),
                dark: AppColor.red(.shade90)
            )
        case .active, .approved:
            self.textColor = UIColor(
                light: AppColor.green(.shade80),
                dark: AppColor.green(.shade10)
            )
            self.backgroundColor = UIColor(
                light: AppColor.green(.shade5),
                dark: AppColor.green(.shade90)
            )
        case .scheduled, .finished:
            self.textColor = UIColor(
                light: AppColor.blue(.shade80),
                dark: AppColor.blue(.shade10)
            )
            self.backgroundColor = UIColor(
                light: AppColor.blue(.shade5),
                dark: AppColor.blue(.shade90)
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
        case .created:
            // There is no dedicated status for `In Moderation` on the backend.
            // The app assumes that the campaign goes into moderation after creation.
            return NSLocalizedString("blazeCampaign.status.inmoderation", value: "In Moderation", comment: "Short status description")
        case .scheduled:
            return NSLocalizedString("blazeCampaign.status.scheduled", value: "Scheduled", comment: "Short status description")
        case .approved:
            return NSLocalizedString("blazeCampaign.status.approved", value: "Approved", comment: "Short status description")
        case .processing:
            // Should never be returned by `ui_status`.
            return NSLocalizedString("blazeCampaign.status.processing", value: "Processing", comment: "Short status description")
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
