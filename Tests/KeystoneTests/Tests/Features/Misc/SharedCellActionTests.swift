import Testing
import UIKit
@testable import WordPress

/// Sends each control event the shared cells used to wire up in their xibs, and checks that it
/// reaches the cell's delegate or callback.
@MainActor
struct SharedCellActionTests {

    @Test func singleLineCellReportsEditsAndValidatesEmail() {
        let spy = SingleLineSpy()
        let cell = InlineEditableSingleLineCell(style: .default, reuseIdentifier: nil)
        cell.configure(text: "jane@example.com", style: .email)
        cell.delegate = spy

        cell.textField.text = "not an email"
        cell.textField.sendActions(for: .editingChanged)

        #expect(spy.updates == 1)
        #expect(cell.isValid == false)
        #expect(cell.textField.delegate === cell)
    }

    @Test func multiLineCellReportsEditsAndKeepsItsMinimumHeight() {
        let spy = MultiLineSpy()
        let cell = InlineEditableMultiLineCell(style: .default, reuseIdentifier: nil)
        cell.delegate = spy

        cell.configure(text: "Short")
        #expect(cell.textView.frame.height == 130)

        cell.textView.delegate?.textViewDidChange?(cell.textView)
        #expect(spy.updates == 1)
    }

    @Test func nameValueCellReportsEdits() {
        let spy = NameValueSpy()
        let cell = InlineEditableNameValueCell(style: .default, reuseIdentifier: nil)
        cell.delegate = spy

        cell.valueTextField.text = "Jane Appleseed"
        cell.valueTextField.sendActions(for: .editingChanged)
        cell.valueTextField.sendActions(for: .editingDidEnd)

        #expect(spy.changes == ["Jane Appleseed"])
        #expect(spy.endings == ["Jane Appleseed"])
        #expect(cell.valueTextField.delegate === cell)
    }

    /// Tapping the name label focuses the text field, so the label must accept touches.
    @Test func nameValueCellLabelAcceptsTaps() {
        let cell = InlineEditableNameValueCell(style: .default, reuseIdentifier: nil)

        #expect(cell.nameLabel.isUserInteractionEnabled)
        #expect(cell.nameLabel.gestureRecognizers?.contains { $0 is UITapGestureRecognizer } == true)
    }

    @Test func nameValueCellDisablesEditingWithAnAccessory() {
        let cell = InlineEditableNameValueCell(style: .default, reuseIdentifier: nil)

        cell.update(with: .init(key: "Country", accessoryType: .disclosureIndicator))

        #expect(cell.valueTextField.isEnabled == false)
    }

    @Test func sliderCellReportsChanges() {
        let cell = MediaSizeSliderCell(style: .default, reuseIdentifier: nil)
        (cell.minValue, cell.maxValue) = (100, 3000)
        var values: [Int] = []
        cell.onChange = { values.append($0) }

        cell.slider.value = 2000
        cell.slider.sendActions(for: .valueChanged)

        #expect(values == [2000])
        #expect(cell.valueLabel.text?.contains("2000") == true)
    }

    @Test func textWithButtonCellReportsTaps() {
        let cell = TextWithAccessoryButtonCell(style: .default, reuseIdentifier: nil)
        var taps = 0
        cell.onButtonTap = { taps += 1 }

        cell.button.sendActions(for: .touchUpInside)

        #expect(taps == 1)
    }

    @Test func expandableCellShowsItsTextWhenExpanded() {
        let cell = ExpandableCell(style: .default, reuseIdentifier: nil)
        #expect(cell.expandableTextView.isHidden)

        cell.toggle()

        #expect(cell.expandableTextView.isHidden == false)
        #expect(cell.expandableTextView.delegate === cell)
    }

    @Test func mediaQuotaCellShowsItsValues() {
        let cell = MediaQuotaCell(style: .default, reuseIdentifier: MediaQuotaCell.defaultReuseIdentifier)

        cell.title = "Space used"
        cell.value = "40%"
        cell.percentage = 0.4

        #expect(cell.titleLabel.text == "Space used")
        #expect(cell.valueLabel.text == "40%")
        #expect(cell.progressView.progress == 0.4)
    }
}

private final class SingleLineSpy: InlineEditableSingleLineCellDelegate {
    var updates = 0
    func textUpdatedForCell(_ cell: InlineEditableSingleLineCell) { updates += 1 }
}

private final class MultiLineSpy: InlineEditableMultiLineCellDelegate {
    var updates = 0
    func textViewHeightUpdatedForCell(_ cell: InlineEditableMultiLineCell) {}
    func textUpdatedForCell(_ cell: InlineEditableMultiLineCell) { updates += 1 }
}

private final class NameValueSpy: NSObject, InlineEditableNameValueCellDelegate {
    var changes: [String] = []
    var endings: [String] = []

    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell, valueTextFieldDidChange value: String) {
        changes.append(value)
    }

    func inlineEditableNameValueCell(_ cell: InlineEditableNameValueCell, valueTextFieldEditingDidEnd text: String) {
        endings.append(text)
    }
}
