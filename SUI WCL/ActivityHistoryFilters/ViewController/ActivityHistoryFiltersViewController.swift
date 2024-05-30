//
//  ActivityHistoryFiltersViewController.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 15.01.24.
//
//

import Combine
import Resources
import SwiftUI
import UIComponents
import UIKit

// MARK: - ActivityHistoryFiltersViewController

final class ActivityHistoryFiltersViewController: DeclarativeController<ActivityHistoryFiltersView> {
    // MARK: - Private Properties

    private let viewModel: ActivityHistoryFiltersViewModel
    private var subscriptions = Set<AnyCancellable>()

    private lazy var resetButton = makeResetButton()

    // MARK: - Initialisers

    init(view: ActivityHistoryFiltersView, viewModel: ActivityHistoryFiltersViewModel) {
        self.viewModel = viewModel

        super.init(content: view)
    }

    required init?(coder _: NSCoder) {
        return nil
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleLabel = AttributedLabel(textStyle: .bodyText)
        titleLabel.text = Strings.Filters.filtersTitle
        navigationItem.titleView = titleLabel

        viewModel.$isResetButtonVisible.sink { [weak self] isResetButtonVisible in
            guard let self else { return }
            self.navigationItem.rightBarButtonItems = isResetButtonVisible ? [self.resetButton] : []
        }.store(in: &subscriptions)
    }

    // MARK: - Private Methods

    private func makeResetButton() -> UIBarButtonItem {
        BarButtonClosureItem(
            title: Strings.ActivityHistory.resetFiltersButton,
            style: .plain,
            tintColor: Colors.black50.color
        ) { [unowned self] in
            withAnimation(.easeOut(duration: 0.15)) {
                viewModel.resetFilters()
            }
        }
    }
}
