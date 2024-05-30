//
//  ActivityHistoryFiltersModuleFactory.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 12.01.24.
//
//

import DataProvider
import Resources
import UIComponents
import UIKit
import Utils

// MARK: - ActivityHistoryFiltersModuleOutput

protocol ActivityHistoryFiltersModuleOutput: AnyObject {
    func activityHistoryFiltersModuleDidRequestToShowActivitiesList(currentServices: [DefaultFilterItem])
    func activityHistoryFiltersModuleDidRequestToShowTrainersList(currentTrainers: [DefaultFilterItem])
    func activityHistoryFiltersModuleDidApplyFilters(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    )
}

// MARK: - ActivityHistoryFiltersUpdater

public protocol ActivityHistoryFiltersUpdater {
    func update(services: [DefaultFilterItem])
    func update(trainers: [DefaultFilterItem])
}

// MARK: - ActivityHistoryFiltersModuleFactory

protocol ActivityHistoryFiltersModuleFactory {
    func createModule(
        moduleOutput delegate: ActivityHistoryFiltersModuleOutput?
    ) -> UpdatableModule<ActivityHistoryFiltersUpdater>
}

// MARK: - MainActivityHistoryFiltersModuleFactory

final class MainActivityHistoryFiltersModuleFactory: ActivityHistoryFiltersModuleFactory {
    private let objectives: [Objective]
    private let currentFilters: ActivityHistoryFilters
    private let services: [DefaultFilterItem]
    private let trainers: [DefaultFilterItem]

    init(
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        self.objectives = objectives
        self.currentFilters = currentFilters
        self.services = services
        self.trainers = trainers
    }

    func createModule(
        moduleOutput delegate: ActivityHistoryFiltersModuleOutput?
    ) -> UpdatableModule<ActivityHistoryFiltersUpdater> {
        // VC/VM Setup
        let viewModel = ActivityHistoryFiltersViewModel(
            objectiveSelectorViewModel: Self.makeObjecticeSelectorViewModel(
                currentFilters: currentFilters,
                objectives: objectives
            ),
            typeSelectorViewModel: Self.makeTypeSelectorViewModel(currentFilters: currentFilters),
            priceSelectorViewModel: Self.makePriceSelectorViewModel(currentFilters: currentFilters),
            services: services,
            trainers: trainers
        )
        viewModel.moduleOutput = delegate
        let view = ActivityHistoryFiltersView(viewModel: viewModel)
        let viewController = ActivityHistoryFiltersViewController(view: view, viewModel: viewModel)
        return UpdatableModule(viewController: viewController, updater: viewModel)
    }

    // MARK: - Private Methods

    private static func makePriceSelectorViewModel(
        currentFilters: ActivityHistoryFilters?
    ) -> CategorySelectorViewModel<ActivityPriceFilter> {
        var preselectedCategories = [ActivityPriceFilter.all]
        if let currentFilters = currentFilters?.paymentTypeFilters, !currentFilters.isEmpty {
            preselectedCategories = currentFilters
        }
        return CategorySelectorViewModel<ActivityPriceFilter>(
            title: Strings.ActivityHistory.filterPriceCategory,
            categories: ActivityPriceFilter.allCases,
            preselectedCategories: preselectedCategories
        )
    }

    private static func makeTypeSelectorViewModel(
        currentFilters: ActivityHistoryFilters?
    ) -> CategorySelectorViewModel<ActivityTypeFilter> {
        var preselectedCategories = [ActivityTypeFilter.all]

        if let currentFilters = currentFilters?.activityTypeFilters, !currentFilters.isEmpty {
            preselectedCategories = currentFilters
        }
        return CategorySelectorViewModel<ActivityTypeFilter>(
            title: Strings.ActivityHistory.filterTypeCategory,
            categories: ActivityTypeFilter.allCases,
            preselectedCategories: preselectedCategories
        )
    }

    private static func makeObjecticeSelectorViewModel(
        currentFilters: ActivityHistoryFilters?,
        objectives: [Objective]
    ) -> CategorySelectorViewModel<ActivityObjectiveType>? {
        guard !objectives.isEmpty else { return nil }
        var preselectedCategories = [
            ActivityObjectiveType(
                id: nil,
                title: Strings.ActivityHistory.allFilter,
                isActive: true,
                objectiveColor: nil,
                isExcluding: true
            )
        ]

        if let currentFilters = currentFilters?.objectiveTypeFilters, !currentFilters.isEmpty {
            preselectedCategories = currentFilters
        }

        var objectivesSelectors = [
            ActivityObjectiveType(
                id: nil,
                title: Strings.ActivityHistory.allFilter,
                isActive: true,
                objectiveColor: nil,
                isExcluding: true
            )
        ]
        objectivesSelectors.append(contentsOf: objectives.map {
            ActivityObjectiveType(
                id: $0.uid,
                title: $0.name,
                isActive: true,
                objectiveColor: $0.color
            )
        })

        return CategorySelectorViewModel<ActivityObjectiveType>(
            title: Strings.ActivityHistory.filterObjectiveCategory,
            categories: objectivesSelectors,
            preselectedCategories: preselectedCategories
        )
    }
}
