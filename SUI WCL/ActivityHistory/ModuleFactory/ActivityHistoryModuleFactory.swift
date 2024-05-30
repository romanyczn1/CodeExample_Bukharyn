//
//  ActivityHistoryModuleFactory.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import ActivityCard
import ActivityRepeat
import Analytics
import CommonModels
import DataProvider
import DataStore
import Payments
import UIComponents
import UIKit
import Utils
import WorkoutBooking

// MARK: - ActivityHistoryModuleInput

struct ActivityHistoryModuleInput {
    let repeatFactory: ActivityRepeatCoordinatorFactory
    let paymentsFactory: PaymentsCoordinatorFactory
    let workoutBooking: WorkoutBookingCoordinatorFactory
    let activeAppExecutor: ActiveAppExecutor
    let asyncAwaitPerformer: AsyncAwaitPerformer
    let analytics: Analytics?
    let clubService: ClubsService
    let clipCardsTrainerManager: ClipCardsTrainerManager
    let activityService: ActivityService
    let externalRouter: ExternalRouter
    let objectivesService: ObjectivesService
    let toaster: Toaster
    let trainerTipsService: TipsCustomURLService
    let trainersService: TrainersService
    let paymentService: PaymentsService
    let servicePackageService: ServicePackagesService
    let scheduleService: DataProvider.ScheduleService
    let widgetService: WidgetService
    let dataStore: UserDataStore
    let scheduleFiltersService: ScheduleFiltersService
    let phoneCalling: PhoneCalling
    let favoritesService: FavoritesService
}

// MARK: - ActivityHistoryModuleOutput

protocol ActivityHistoryModuleOutput: AnyObject {
    func userDidRequestToShowActivityCard(from activity: Activity)
    func userDidRequestToShowFilters(
        objectives: [Objective],
        currentFilters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    )
    func repeatActivity(kind: ActivityRepeaterKind)
}

// MARK: - ActivityHistoryUpdater

protocol ActivityHistoryUpdater {
    func reloadData()
    func filtersChanged(
        filters: ActivityHistoryFilters,
        services: [DefaultFilterItem],
        trainers: [DefaultFilterItem]
    )
}

// MARK: - ActivityHistoryModuleFactory

protocol ActivityHistoryModuleFactory {
    func createModule(
        activities: [Activity]?,
        moduleOutput delegate: ActivityHistoryModuleOutput?
    ) -> UpdatableModule<ActivityHistoryUpdater>

    func createActivityCardCoordinator(
        activityCardInput: ActivityCardModuleInputData,
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?
    ) -> ActivityCardCoordinator

    func createWorkoutRepeatCoordinator(
        kind: ActivityRepeaterKind,
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?,
        onFinish: @escaping () -> Void
    ) -> ActivityRepeatCoordinator
}

// MARK: - MainActivityHistoryModuleFactory

final class MainActivityHistoryModuleFactory: ActivityHistoryModuleFactory {
    private let moduleInput: ActivityHistoryModuleInput

    init(moduleInput: ActivityHistoryModuleInput) {
        self.moduleInput = moduleInput
    }

    func createModule(
        activities: [Activity]?,
        moduleOutput delegate: ActivityHistoryModuleOutput?
    ) -> UpdatableModule<ActivityHistoryUpdater> {
        let service = ActivityHistoryService(
            activityService: moduleInput.activityService,
            objectivesService: moduleInput.objectivesService
        )
        let worker = ActivityHistoryWorker(
            analytics: moduleInput.analytics,
            dataStore: ActivityHistoryDataStore(),
            service: service,
            defaultActivities: activities
        )

        let viewModel = ActivityHistoryViewModel(worker: worker)
        viewModel.moduleOutput = delegate
        let view = ActivityHistoryView(viewModel: viewModel)
        let viewController = ActivityHistoryViewController(viewModel: viewModel, content: view)
        return UpdatableModule(
            viewController: viewController,
            updater: viewModel
        )
    }

    func createActivityCardCoordinator(
        activityCardInput: ActivityCardModuleInputData,
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?
    ) -> ActivityCardCoordinator {
        let factory = MainActivityCardCoordinatorFactory(
            analytics: moduleInput.analytics,
            activeAppExecutor: moduleInput.activeAppExecutor,
            activityService: moduleInput.activityService,
            asyncAwaitPerformer: moduleInput.asyncAwaitPerformer,
            clubService: moduleInput.clubService,
            clipCardsTrainerManager: moduleInput.clipCardsTrainerManager,
            dataStore: moduleInput.dataStore,
            externalRouter: moduleInput.externalRouter,
            repeatWorkoutFactory: moduleInput.repeatFactory,
            paymentCoordinatorFactory: moduleInput.paymentsFactory,
            workoutBookingCoordinatorFactory: moduleInput.workoutBooking,
            objectivesService: moduleInput.objectivesService,
            trainerTipsService: moduleInput.trainerTipsService,
            trainersService: moduleInput.trainersService,
            toaster: moduleInput.toaster,
            servicePackageService: moduleInput.servicePackageService,
            paymentService: moduleInput.paymentService,
            scheduleService: moduleInput.scheduleService,
            widgetService: moduleInput.widgetService,
            scheduleFiltersService: moduleInput.scheduleFiltersService,
            phoneCalling: moduleInput.phoneCalling,
            favoritesService: moduleInput.favoritesService
        )
        return factory.createActivityCardCoordinator(
            activityCardInput: activityCardInput,
            navigationController: navigationController,
            navigationObserver: navigationObserver
        )
    }

    func createWorkoutRepeatCoordinator(
        kind: ActivityRepeaterKind,
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?,
        onFinish: @escaping () -> Void
    ) -> ActivityRepeatCoordinator {
        let params = ActivityRepeatParams(
            kind: kind,
            navigationController: navigationController,
            navigationObserver: navigationObserver,
            onFinish: onFinish
        )
        return moduleInput.repeatFactory.make(input: params)
    }
}
