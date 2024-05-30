//
//  ActivityHistoryFiltersCoordinator.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 12.01.24.
//
//

import DataProvider
import Filter
import Foundation
import UIComponents
import UIKit
import Utils

// MARK: - ActivityHistoryFiltersCoordinatorDelegate

protocol ActivityHistoryFiltersCoordinatorDelegate: AnyObject {
    func coordinatorDidFinish(_ coordinator: ActivityHistoryFiltersCoordinator)
    func coordinatorDidChangeFilters(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    )
}

// MARK: - ActivityHistoryFiltersCoordinator

protocol ActivityHistoryFiltersCoordinator: Coordinator {
    var delegate: ActivityHistoryFiltersCoordinatorDelegate? { get set }
}

// MARK: - MainActivityHistoryFiltersCoordinator

final class MainActivityHistoryFiltersCoordinator: NSObject, ActivityHistoryFiltersCoordinator {
    // MARK: - Properties

    weak var delegate: ActivityHistoryFiltersCoordinatorDelegate?
    public var childCoordinators: [Coordinator] = []
    public var navigationController: UINavigationController
    public var viewController: UIViewController? {
        presentedMainNavigationController?.topViewController
    }

    private weak var presentedMainNavigationController: UINavigationController?

    private let servicesSelectionModuleFactory: FilterItemSelectionModuleFactory
    private let trainersSelectionModuleFactory: FilterItemSelectionModuleFactory

    private let moduleFactory: ActivityHistoryFiltersModuleFactory

    private var filtersModule: UpdatableModule<ActivityHistoryFiltersUpdater>?

    // MARK: - Init

    init(
        navigationController: UINavigationController,
        moduleFactory: ActivityHistoryFiltersModuleFactory,
        servicesSelectionModuleFactory: FilterItemSelectionModuleFactory,
        trainersSelectionModuleFactory: FilterItemSelectionModuleFactory
    ) {
        self.navigationController = navigationController
        self.moduleFactory = moduleFactory
        self.servicesSelectionModuleFactory = servicesSelectionModuleFactory
        self.trainersSelectionModuleFactory = trainersSelectionModuleFactory
    }

    // MARK: - Navigation

    public func start() {
        let module = moduleFactory.createModule(moduleOutput: self)
        let nc = ModalNavigationController(rootViewController: module.viewController)
        nc.modalDelegate = self
        navigationController.present(nc, animated: true)

        filtersModule = module
        presentedMainNavigationController = nc
    }

    // MARK: - Public Methods

    // MARK: - Private Methods

    private func showActivities(currentServices: [DefaultFilterItem]) {
        let module = servicesSelectionModuleFactory.make(
            type: .activities,
            items: currentServices,
            moduleOutput: self
        )
        presentedMainNavigationController?.pushViewController(module.viewController, animated: true)
    }

    private func showTrainers(currentTrainers: [DefaultFilterItem]) {
        let module = trainersSelectionModuleFactory.make(
            type: .activitiesTrainers,
            items: currentTrainers,
            moduleOutput: self
        )
        presentedMainNavigationController?.pushViewController(module.viewController, animated: true)
    }

    private func finish() {
        presentedMainNavigationController?.dismiss(animated: true) { [unowned self] in
            delegate?.coordinatorDidFinish(self)
        }
    }
}

// MARK: ActivityHistoryFiltersModuleOutput

extension MainActivityHistoryFiltersCoordinator: ActivityHistoryFiltersModuleOutput {
    func activityHistoryFiltersModuleDidRequestToShowActivitiesList(currentServices: [DefaultFilterItem]) {
        showActivities(currentServices: currentServices)
    }

    func activityHistoryFiltersModuleDidRequestToShowTrainersList(currentTrainers: [DefaultFilterItem]) {
        showTrainers(currentTrainers: currentTrainers)
    }

    func activityHistoryFiltersModuleDidApplyFilters(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    ) {
        delegate?.coordinatorDidChangeFilters(
            filters: filters,
            services: services,
            trainers: trainers
        )
        finish()
    }
}

// MARK: FilterItemSelectionModuleOutput

extension MainActivityHistoryFiltersCoordinator: FilterItemSelectionModuleOutput {
    public func filterItemSelectionModuleDidUpdateSelection(items: [any FilterItem]) {
        if let services = items as? [DefaultFilterItem] {
            filtersModule?.updater.update(services: services)
        }
        if let trainers = items as? [DefaultFilterItem] {
            filtersModule?.updater.update(trainers: trainers)
        }
        presentedMainNavigationController?.popViewController(animated: true)
    }
}

// MARK: ModalViewControllerDelegate

extension MainActivityHistoryFiltersCoordinator: ModalViewControllerDelegate {
    public func modalViewControllerDidRequestClose(_ controller: UIComponents.ModalViewController) {
        finish()
    }
}
