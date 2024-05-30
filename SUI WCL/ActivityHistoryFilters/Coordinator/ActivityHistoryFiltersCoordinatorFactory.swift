//
//  ActivityHistoryFiltersCoordinatorFactory.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 12.01.24.
//
//

import Analytics
import DataProvider
import Filter
import UIComponents
import UIKit
import Utils

// MARK: - ActivityHistoryFiltersCoordinatorFactory

protocol ActivityHistoryFiltersCoordinatorFactory {
    func createActivityHistoryFiltersCoordinator(
        navigationController: UINavigationController,
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) -> ActivityHistoryFiltersCoordinator
}

// MARK: - MainActivityHistoryFiltersCoordinatorFactory

final class MainActivityHistoryFiltersCoordinatorFactory: ActivityHistoryFiltersCoordinatorFactory {
    private let analyticService: Analytics?
    private let activityHistoryFiltersService: DataProvider.ActivityHistoryFiltersService
    private let asyncAwaitPerformer: AsyncAwaitPerformer
    private let toaster: Toaster

    // MARK: - Init

    init(
        analyticService: Analytics?,
        activityHistoryFiltersService: DataProvider.ActivityHistoryFiltersService,
        asyncAwaitPerformer: AsyncAwaitPerformer,
        toaster: Toaster
    ) {
        self.analyticService = analyticService
        self.activityHistoryFiltersService = activityHistoryFiltersService
        self.asyncAwaitPerformer = asyncAwaitPerformer
        self.toaster = toaster
    }

    public func createActivityHistoryFiltersCoordinator(
        navigationController: UINavigationController,
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) -> ActivityHistoryFiltersCoordinator {
        let moduleFactory = MainActivityHistoryFiltersModuleFactory(
            objectives: objectives,
            currentFilters: currentFilters,
            services: services,
            trainers: trainers
        )

        let filterItemSelectionModuleInput = FilterItemSelectionModuleInput(
            analytics: analyticService,
            toaster: toaster,
            asyncAwaitPerformer: asyncAwaitPerformer
        )
        let servicesSelectionModuleFactory = FilterItemSelectionModuleFactory(
            input: filterItemSelectionModuleInput,
            itemProvider: activityHistoryFiltersService.getActivityHistoryActivities
        )
        let trainersSelectionModuleFactory = FilterItemSelectionModuleFactory(
            input: filterItemSelectionModuleInput,
            itemProvider: activityHistoryFiltersService.getActivityHistoryTrainers
        )

        return MainActivityHistoryFiltersCoordinator(
            navigationController: navigationController,
            moduleFactory: moduleFactory,
            servicesSelectionModuleFactory: servicesSelectionModuleFactory,
            trainersSelectionModuleFactory: trainersSelectionModuleFactory
        )
    }
}
