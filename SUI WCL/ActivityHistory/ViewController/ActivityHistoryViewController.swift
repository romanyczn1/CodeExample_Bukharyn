//
//  ActivityHistoryViewController.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import Combine
import Resources
import UIComponents
import UIKit

final class ActivityHistoryViewController: DeclarativeController<ActivityHistoryView> {
    private let viewModel: ActivityHistoryViewModel

    private var subscriptions = Set<AnyCancellable>()

    init(
        viewModel: ActivityHistoryViewModel,
        content: ActivityHistoryView
    ) {
        self.viewModel = viewModel

        super.init(content: content)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let filtersButton = makeFiltersButton()

        viewModel.$state.sink { [weak self] _ in
            guard let self else { return }

            self.navigationItem.rightBarButtonItem = filtersButton
            filtersButton.image = self.viewModel.isFiltersActive ? Images.filterActive.image : Images.filter.image
        }.store(in: &subscriptions)
    }

    private func makeFiltersButton() -> UIBarButtonItem {
        BarButtonClosureItem(image: Images.filterSmall.image, style: .plain) { [weak self] in
            guard let self = self else { return }
            self.viewModel.openFilters()
        }
    }
}
