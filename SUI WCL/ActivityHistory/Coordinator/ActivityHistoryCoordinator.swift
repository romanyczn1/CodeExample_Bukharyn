//
//  ActivityHistoryCoordinator.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import ActivityCard
import ActivityRepeat
import CommonModels
import CustomActivityCard
import DataProvider
import Foundation
import Resources
import UIComponents
import UIKit
import Utils

// MARK: - ActivityHistoryCoordinatorDelegate

public protocol ActivityHistoryCoordinatorDelegate: AnyObject {
    func coordinatorDidFinish(_ coordinator: ActivityHistoryCoordinator)
}

// MARK: - ActivityHistoryCoordinator

public protocol ActivityHistoryCoordinator: Coordinator, NavigationPopObserver {
    var delegate: ActivityHistoryCoordinatorDelegate? { get set }
}

// MARK: - MainActivityHistoryCoordinator

public final class MainActivityHistoryCoordinator: NSObject, ActivityHistoryCoordinator {
    // MARK: - Properties

    public weak var delegate: ActivityHistoryCoordinatorDelegate?

    public var childCoordinators: [Coordinator] = []
    public var navigationController: UINavigationController
    public var navigationObserver: NavigationObserver?
    public var viewController: UIViewController?

    private var repeatCoordinator: ActivityRepeatCoordinator?

    private let customActivityCoordinatorFactory: CustomActivityCardCoordinatorFactory
    private let activityHistoryFiltersCoordinatorFactory: ActivityHistoryFiltersCoordinatorFactory
    private let moduleFactory: ActivityHistoryModuleFactory
    private var module: UpdatableModule<ActivityHistoryUpdater>?

    private let activities: [Activity]?

    // MARK: - Init

    init(
        activities: [Activity]?,
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?,
        moduleFactory: ActivityHistoryModuleFactory,
        customActivityCoordinatorFactory: CustomActivityCardCoordinatorFactory,
        activityHistoryFiltersCoordinatorFactory: ActivityHistoryFiltersCoordinatorFactory
    ) {
        self.activities = activities
        self.navigationController = navigationController
        self.moduleFactory = moduleFactory
        self.customActivityCoordinatorFactory = customActivityCoordinatorFactory
        self.activityHistoryFiltersCoordinatorFactory = activityHistoryFiltersCoordinatorFactory
        self.navigationObserver = navigationObserver
    }

    // MARK: - Navigation

    public func start() {
        let module = moduleFactory.createModule(activities: activities, moduleOutput: self)
        module.viewController.title = Strings.ActivityHistory.screenTitle
        self.module = module
        navigationController.pushViewController(module.viewController, animated: true)
        navigationObserver?.addObserver(self, forPopOf: module.viewController)
    }

    // MARK: - Private Methods

    private func showActivityCardScreen(from activity: ClubActivity) {
        let coordinator = moduleFactory.createActivityCardCoordinator(
            activityCardInput: .init(
                clubActivity: activity,
                isRepeatableAppointment: nil,
                isBooked: false
            ),
            navigationController: navigationController,
            navigationObserver: navigationObserver
        )
        coordinator.delegate = self
        coordinator.start()
        childCoordinators.append(coordinator)
    }

    private func showCustomActivityCard(scenario: CustomActivityCardScenario) {
        let coordinator = customActivityCoordinatorFactory
            .createCustomActivityCardCoordinator(
                navigationController: navigationController,
                navigationObserver: navigationObserver,
                scenario: scenario
            )
        coordinator.delegate = self
        coordinator.start()
        childCoordinators.append(coordinator)
    }

    private func showFiltersScreen(
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        let coordinator = activityHistoryFiltersCoordinatorFactory.createActivityHistoryFiltersCoordinator(
            navigationController: navigationController,
            objectives: objectives,
            currentFilters: currentFilters,
            services: services,
            trainers: trainers
        )
        coordinator.delegate = self
        coordinator.start()
        childCoordinators.append(coordinator)
    }
}

// MARK: - NavigationPopObserver

extension MainActivityHistoryCoordinator {
    public func navigationObserver(
        _ observer: NavigationObserver,
        didObserveViewControllerPop viewController: UIViewController
    ) {
        delegate?.coordinatorDidFinish(self)
    }
}

// MARK: ActivityHistoryModuleOutput

extension MainActivityHistoryCoordinator: ActivityHistoryModuleOutput {
    func userDidRequestToShowActivityCard(from activity: Activity) {
        switch activity.activity {
        case .selfActivity:
            showCustomActivityCard(scenario: .read(activityID: activity.uid))
        case .clubActivity(let clubActivity):
            showActivityCardScreen(from: clubActivity)
        }
    }

    func repeatActivity(kind: ActivityRepeaterKind) {
        repeatCoordinator = moduleFactory.createWorkoutRepeatCoordinator(
            kind: kind,
            navigationController: navigationController,
            navigationObserver: navigationObserver,
            onFinish: { [weak self] in
                guard let self = self else { return }
                self.repeatCoordinator = nil
            }
        )

        repeatCoordinator?.start()
    }

    func userDidRequestToShowFilters(
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        showFiltersScreen(
            objectives: objectives,
            currentFilters: currentFilters,
            services: services,
            trainers: trainers
        )
    }
}

// MARK: ActivityCardCoordinatorDelegate

extension MainActivityHistoryCoordinator: ActivityCardCoordinatorDelegate {
    public func coordinatorDidFinish(_ coordinator: ActivityCardCoordinator) {
        remove(coordinator: coordinator)
    }
}

// MARK: CustomActivityCardCoordinatorDelegate

extension MainActivityHistoryCoordinator: CustomActivityCardCoordinatorDelegate {
    public func coordinatorDidFinish(
        _ coordinator: CustomActivityCard.CustomActivityCardCoordinator,
        hasChanges: Bool
    ) {
        remove(coordinator: coordinator)
        if hasChanges {
            module?.updater.reloadData()
        }
    }
}

// MARK: ActivityHistoryFiltersCoordinatorDelegate

extension MainActivityHistoryCoordinator: ActivityHistoryFiltersCoordinatorDelegate {
    func coordinatorDidFinish(_ coordinator: ActivityHistoryFiltersCoordinator) {
        remove(coordinator: coordinator)
    }

    func coordinatorDidChangeFilters(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        module?.updater.filtersChanged(
            filters: filters,
            services: services,
            trainers: trainers
        )
    }
}
