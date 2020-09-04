//
//  PostItineraryDateViewController.swift
//  BeauVoyage
//
//  Created by Lukasz Koszentka on 7/28/20.
//  Copyright © 2020 BeauVoyage. All rights reserved.
//

import UIKit

final class PostItineraryDateViewController: UIViewController {

    @IBOutlet weak var startDateTextField: UITextField!
    @IBOutlet weak var endDateTextField: UITextField!

    private let startDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        return datePicker
    }()

    private let endDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        return datePicker
    }()

    private let viewModel: PostItineraryDateViewModel

    @objc public init(viewModel: PostItineraryDateViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupView() {
        navigationItem.setHidesBackButton(true, animated: true)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.saveButtonTitle,
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(save))
        navigationItem.rightBarButtonItem?.isEnabled = false
        title = viewModel.title
        startDateTextField.inputView = startDatePicker
        startDateTextField.placeholder = viewModel.startDatePlaceholder
        endDateTextField.inputView = endDatePicker
        endDateTextField.placeholder = viewModel.endDatePlaceholder
        startDatePicker.addTarget(self, action: #selector(handleStartDatePicker(sender:)), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(handleEndDatePicker(sender:)), for: .valueChanged)
    }

    @objc func save() {
        if let controller = PostCategoriesViewController(blog: viewModel.post.blog,
                                                         currentSelection: viewModel.post.categories?.map({ $0 }) ?? [],
                                                      selectionMode: CategoriesSelectionModeBeauVoyageAddPost) {
            controller.delegate = self
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc func handleStartDatePicker(sender: UIDatePicker) {
        viewModel.changeStartDate(date: sender.date)
    }

    @objc func handleEndDatePicker(sender: UIDatePicker) {
        viewModel.changeEndDate(date: sender.date)
    }

}

extension PostItineraryDateViewController: PostCategoriesViewControllerDelegate {

    func postCategoriesViewController(_ controller: PostCategoriesViewController!, didUpdateSelectedCategories categories: Set<AnyHashable>!) {
        if let categories = categories as? Set<PostCategory>? {
            viewModel.post.categories = categories
        }
    }

}

extension PostItineraryDateViewController: PostItineraryDateViewModelDelegate {

    func startDateChanged(date: String) {
        startDateTextField.text = date
        handleSaveButtonState()
    }

    func endDateChanged(date: String) {
        endDateTextField.text = date
        handleSaveButtonState()
    }

    private func handleSaveButtonState() {
        guard let start = startDateTextField.text?.isEmpty, let end = endDateTextField.text?.isEmpty else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        navigationItem.rightBarButtonItem?.isEnabled = !start && !end
    }

}
