import Foundation
import DGCharts
import UIKit

final class ViewsVisitorsChartMarker: MarkerView {
    var dotColor: UIColor
    var name: String
    var minimumSize = CGSize()

    private var tooltipLabel: NSMutableAttributedString?
    private var labelSize: CGSize = CGSize()
    private var size: CGSize = CGSize()
    private var paragraphStyle: NSMutableParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 4.0
        return paragraphStyle
    }()

    public init(dotColor: UIColor, name: String) {
        self.dotColor = dotColor
        self.name = name

        super.init(frame: CGRect.zero)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func drawRect(context: CGContext, point: CGPoint) -> CGRect {
        let chart = super.chartView
        let width = size.width

        var rect = CGRect(origin: point, size: size)

        if point.y - size.height < 0 {
            if point.x - size.width / 2.0 < 0 {
                drawTopLeftRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            } else if let chartWidth = chart?.bounds.width, point.x + width - size.width / 2.0 > chartWidth {
                rect.origin.x -= size.width
                drawTopRightRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            } else {
                rect.origin.x -= size.width / 2.0
                drawTopCenterRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            }

            rect.origin.y += Constants.topInsets.top
            rect.size.height -= Constants.topInsets.top + Constants.topInsets.bottom
        } else {
            rect.origin.y -= size.height

            if point.x - size.width / 2.0 < 0 {
                drawLeftRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            } else if let chartWidth = chart?.bounds.width, point.x + width - size.width / 2.0 > chartWidth {
                rect.origin.x -= size.width
                drawRightRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            } else {
                rect.origin.x -= size.width / 2.0
                drawCenterRect(context: context, x: rect.origin.x, y: rect.origin.y, height: rect.height, width: rect.width)
            }

            rect.origin.y += Constants.insets.top
            rect.size.height -= Constants.insets.top + Constants.insets.bottom
        }

        return rect
    }

    func drawDot(context: CGContext, xPosition: CGFloat, yPosition: CGFloat) {
        context.setLineWidth(Constants.dotBorderWidth)
        context.setStrokeColor(Constants.dotBorderColor)
        context.setFillColor(dotColor.cgColor)
        context.setShadow(offset: CGSize.zero, blur: Constants.shadowBlur, color: Constants.shadowColor)

        let square = CGRect(x: xPosition, y: yPosition, width: Constants.dotRadius * 2, height: Constants.dotRadius * 2)
        context.addEllipse(in: square)
        context.drawPath(using: .fillStroke)
    }

    func drawCenterRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height
        let arrowWidth = Constants.arrowSize.width

        drawDot(context: context, xPosition: x + width / 2.0 - Constants.dotRadius, yPosition: y + height - Constants.dotRadius)

        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x + Constants.cornerRadius, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - Constants.cornerRadius, y: y - Constants.dotRadius))
        // Top right corner
        context.addQuadCurve(to: CGPoint(x: x + width, y: y + Constants.cornerRadius - Constants.dotRadius), control: CGPoint(x: x + width, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + height - arrowHeight - Constants.cornerRadius - Constants.dotRadius))
        // Bottom right corner
        context.addQuadCurve(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + height - arrowHeight - Constants.dotRadius), control: CGPoint(x: x + width, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + (width + arrowWidth) / 2.0, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width / 2.0, y: y + height - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + (width - arrowWidth) / 2.0, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + Constants.cornerRadius, y: y + height - arrowHeight - Constants.dotRadius))
        // Bottom left corner
        context.addQuadCurve(to: CGPoint(x: x, y: y + height - arrowHeight - Constants.cornerRadius - Constants.dotRadius), control: CGPoint(x: x, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + Constants.cornerRadius - Constants.dotRadius))
        // Top left corner
        context.addQuadCurve(to: CGPoint(x: x + Constants.cornerRadius, y: y - Constants.dotRadius), control: CGPoint(x: x, y: y - Constants.dotRadius))
        context.fillPath()
    }

    func drawLeftRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height
        let arrowWidth = Constants.arrowSize.width

        drawDot(context: context, xPosition: x - Constants.dotRadius, yPosition: y + height - Constants.dotRadius)

        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - Constants.cornerRadius, y: y - Constants.dotRadius))
        // Top right corner
        context.addQuadCurve(to: CGPoint(x: x + width, y: y + Constants.cornerRadius - Constants.dotRadius), control: CGPoint(x: x + width, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + height - arrowHeight - Constants.cornerRadius - Constants.dotRadius))
        // Bottom right corner
        context.addQuadCurve(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + height - arrowHeight - Constants.dotRadius), control: CGPoint(x: x + width, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + arrowWidth / 2.0, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + height - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + Constants.cornerRadius - Constants.dotRadius))
        // Top left corner
        context.addQuadCurve(to: CGPoint(x: x + Constants.cornerRadius, y: y - Constants.dotRadius), control: CGPoint(x: x, y: y - Constants.dotRadius))
        context.fillPath()
    }

    func drawRightRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height
        let arrowWidth = Constants.arrowSize.width

        drawDot(context: context, xPosition: x + width - Constants.dotRadius, yPosition: y + height - Constants.dotRadius)

        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x + Constants.cornerRadius, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - Constants.cornerRadius, y: y - Constants.dotRadius))
        // Top right corner
        context.addQuadCurve(to: CGPoint(x: x + width, y: y + Constants.cornerRadius - Constants.dotRadius), control: CGPoint(x: x + width, y: y - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + height - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - arrowWidth / 2.0, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + Constants.cornerRadius, y: y + height - arrowHeight - Constants.dotRadius))
        // Bottom left corner
        context.addQuadCurve(to: CGPoint(x: x, y: y + height - arrowHeight - Constants.cornerRadius - Constants.dotRadius), control: CGPoint(x: x, y: y + height - arrowHeight - Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + Constants.cornerRadius - Constants.dotRadius))
        // Top left corner
        context.addQuadCurve(to: CGPoint(x: x + Constants.cornerRadius, y: y - Constants.dotRadius), control: CGPoint(x: x, y: y - Constants.dotRadius))
        context.fillPath()
    }

    func drawTopCenterRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height
        let arrowWidth = Constants.arrowSize.width

        drawDot(context: context, xPosition: x + width / 2.0 - Constants.dotRadius, yPosition: y - Constants.dotRadius)
        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x + width / 2.0, y: y + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + (width + arrowWidth) / 2.0, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + arrowHeight + Constants.dotRadius))
        // Top right corner
        context.addQuadCurve(to: CGPoint(x: x + width, y: y + arrowHeight + Constants.cornerRadius + Constants.dotRadius), control: CGPoint(x: x + width, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + height - Constants.cornerRadius + Constants.dotRadius))
        // Bottom right corner
        context.addQuadCurve(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + height + Constants.dotRadius), control: CGPoint(x: x + width, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + Constants.cornerRadius, y: y + height + Constants.dotRadius))
        // Bottom left corner
        context.addQuadCurve(to: CGPoint(x: x, y: y + height - Constants.cornerRadius + Constants.dotRadius), control: CGPoint(x: x, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + arrowHeight + Constants.cornerRadius + Constants.dotRadius))
        // Top left corner
        context.addQuadCurve(to: CGPoint(x: x + Constants.cornerRadius, y: y + arrowHeight + Constants.dotRadius), control: CGPoint(x: x, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + (width - arrowWidth) / 2.0, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width / 2.0, y: y + Constants.dotRadius))
        context.fillPath()
    }

    func drawTopLeftRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height
        let arrowWidth = Constants.arrowSize.width

        drawDot(context: context, xPosition: x - Constants.dotRadius, yPosition: y - Constants.dotRadius)

        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x, y: y + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + arrowWidth / 2.0, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + arrowHeight + Constants.dotRadius))
        // Top right corner
        context.addQuadCurve(to: CGPoint(x: x + width, y: y + arrowHeight + Constants.cornerRadius + Constants.dotRadius), control: CGPoint(x: x + width, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y - Constants.cornerRadius + height + Constants.dotRadius))
        // Bottom right corner
        context.addQuadCurve(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + height + Constants.dotRadius), control: CGPoint(x: x + width, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + Constants.cornerRadius, y: y + height + Constants.dotRadius))
        // Bottom left corner
        context.addQuadCurve(to: CGPoint(x: x, y: y + height - Constants.cornerRadius + Constants.dotRadius), control: CGPoint(x: x, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + Constants.dotRadius))
        context.fillPath()
    }

    func drawTopRightRect(context: CGContext, x: CGFloat, y: CGFloat, height: CGFloat, width: CGFloat) {
        let arrowHeight = Constants.arrowSize.height

        drawDot(context: context, xPosition: x + width - Constants.dotRadius, yPosition: y - Constants.dotRadius)

        // Draw tooltip
        context.setFillColor(Constants.tooltipColor.cgColor)
        context.beginPath()
        context.move(to: CGPoint(x: x + width, y: y + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + height + Constants.dotRadius - Constants.cornerRadius))
        // Bottom right corner
        context.addQuadCurve(to: CGPoint(x: x + width - Constants.cornerRadius, y: y + height + Constants.dotRadius), control: CGPoint(x: x + width, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + Constants.cornerRadius, y: y + height + Constants.dotRadius))
        // Bottom left corner
        context.addQuadCurve(to: CGPoint(x: x, y: y + height - Constants.cornerRadius + Constants.dotRadius), control: CGPoint(x: x, y: y + height + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x, y: y + arrowHeight + Constants.cornerRadius + Constants.dotRadius))
        // Top left corner
        context.addQuadCurve(to: CGPoint(x: x + Constants.cornerRadius, y: y + arrowHeight + Constants.dotRadius), control: CGPoint(x: x, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width - arrowHeight / 2.0, y: y + arrowHeight + Constants.dotRadius))
        context.addLine(to: CGPoint(x: x + width, y: y + Constants.dotRadius))
        context.fillPath()
    }

    override func draw(context: CGContext, point: CGPoint) {
        guard let tooltipLabel = tooltipLabel else {
            return
        }

        context.saveGState()
        let rect = drawRect(context: context, point: point)
        UIGraphicsPushContext(context)
        tooltipLabel.draw(in: rect)
        UIGraphicsPopContext()
        context.restoreGState()
    }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let yValue = Int(entry.y).description

        guard let data = chartView?.data, data.dataSetCount > 1, let lineChartDataSetPrevWeek = data.dataSet(at: 1) as? LineChartDataSet else {
            return
        }

        let entryPrevWeek = lineChartDataSetPrevWeek.entries[Int(entry.x)]
        let difference = Int(entry.y - entryPrevWeek.y)
        let differenceStr = difference < 0 ? "\(difference)" : "+\(difference)"

        var roundedPercentage = 0
        if entryPrevWeek.y > 0 {
            let percentage = (Float(difference) / Float(entryPrevWeek.y)) * 100
            roundedPercentage = Int(round(percentage))
        }

        let topRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .footnote),
                                                               .paragraphStyle: paragraphStyle,
                                                               .foregroundColor: UIColor.white.withAlphaComponent(0.8)]
        let bottomRowAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.preferredFont(forTextStyle: .headline),
                                                                  .paragraphStyle: paragraphStyle,
                                                                  .foregroundColor: UIColor.white]

        let topRowStr = NSMutableAttributedString(string: "\(differenceStr) (\(roundedPercentage)%)\n", attributes: topRowAttributes)
        let bottomRowStr = NSAttributedString(string: "\(yValue) \(name)", attributes: bottomRowAttributes)

        topRowStr.append(bottomRowStr)
        tooltipLabel = topRowStr

        labelSize = topRowStr.size()
        size.width = labelSize.width + Constants.insets.left + Constants.insets.right
        size.height = labelSize.height + Constants.insets.top + Constants.insets.bottom
        size.width = max(minimumSize.width, size.width)
        size.height = max(minimumSize.height, size.height)
    }
}

private extension ViewsVisitorsChartMarker {
    enum Constants {
        static var tooltipColor: UIColor {
            return UIColor(color: .muriel(name: .blue, .shade100))
        }

        static var shadowColor: CGColor {
            return UIColor(red: 50 / 255, green: 50 / 255, blue: 71 / 255, alpha: 0.06).cgColor
        }

        static var dotBorderColor: CGColor {
            return UIColor.white.cgColor
        }

        static let arrowSize = CGSize(width: 12, height: 8)
        static let insets = UIEdgeInsets(top: 2.0, left: 16.0, bottom: 26.0, right: 16.0)
        static let topInsets = UIEdgeInsets(top: 26.0, left: 8.0, bottom: 2.0, right: 8.0)
        static let dotRadius = 8.0
        static let dotBorderWidth = 4.0
        static let cornerRadius = 10.0
        static let shadowBlur = 5.0
    }
}
