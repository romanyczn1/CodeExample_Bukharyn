//
//  ActivityHistoryCoordinatorFactory.swift
//  ActivityHistory
//
//  Created by Raman Bukharyn on 11.01.24.
//
//

import ActivityRepeat
import Analytics
import CustomActivityCard
import DataProvider
import DataStore
import Payments
import UIComponents
import UIKit
import Utils
import WorkoutBooking

// MARK: - ActivityHistoryCoordinatorFactory

public protocol ActivityHistoryCoordinatorFactory {
    func createActivityHistoryCoordinator(
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?,
        repeatFactory: ActivityRepeatCoordinatorFactory,
        paymentsFactory: PaymentsCoordinatorFactory,
        workoutBooking: WorkoutBookingCoordinatorFactory,
        activities: [Activity]?
    ) -> ActivityHistoryCoordinator
}

// MARK: - MainActivityHistoryCoordinatorFactory

public final class MainActivityHistoryCoordinatorFactory: ActivityHistoryCoordinatorFactory {
    // MARK: - Properties

    private let activityService: ActivityService
    private let activeAppExecutor: ActiveAppExecutor
    private let activityHistoryFiltersService: DataProvider.ActivityHistoryFiltersService
    private let asyncAwaitPerformer: AsyncAwaitPerformer
    private let analytics: Analytics?
    private let clubService: ClubsService
    private let clipCardsTrainerManager: ClipCardsTrainerManager
    private let externalRouter: ExternalRouter
    private let dataStore: UserDataStore
    private let toaster: Toaster
    private let objectivesService: ObjectivesService
    private let trainerTipsService: TipsCustomURLService
    private let trainersService: TrainersService
    private let paymentService: PaymentsService
    private let servicePackageService: ServicePackagesService
    private let scheduleService: DataProvider.ScheduleService
    private let widgetService: WidgetService
    private let scheduleFiltersService: ScheduleFiltersService
    private let phoneCalling: PhoneCalling
    private let favoritesService: FavoritesService

    // MARK: - Init
    public init(
        activeAppExecutor: ActiveAppExecutor,
        activityHistoryFiltersService: DataProvider.ActivityHistoryFiltersService,
        activityService: ActivityService,
        asyncAwaitPerformer: AsyncAwaitPerformer,
        analytics: Analytics?,
        clubService: ClubsService,
        clipCardsTrainerManager: ClipCardsTrainerManager,
        externalRouter: ExternalRouter,
        dataStore: UserDataStore,
        toaster: Toaster,
        objectivesService: ObjectivesService,
        trainerTipsService: TipsCustomURLService,
        trainersService: TrainersService,
        paymentService: PaymentsService,
        servicePackageService: ServicePackagesService,
        scheduleService: DataProvider.ScheduleService,
        widgetService: WidgetService,
        scheduleFiltersService: ScheduleFiltersService,
        phoneCalling: PhoneCalling,
        favoritesService: FavoritesService
    ) {
        self.activityService = activityService
        self.activeAppExecutor = activeAppExecutor
        self.activityHistoryFiltersService = activityHistoryFiltersService
        self.asyncAwaitPerformer = asyncAwaitPerformer
        self.analytics = analytics
        self.clubService = clubService
        self.clipCardsTrainerManager = clipCardsTrainerManager
        self.externalRouter = externalRouter
        self.dataStore = dataStore
        self.toaster = toaster
        self.objectivesService = objectivesService
        self.trainerTipsService = trainerTipsService
        self.trainersService = trainersService
        self.paymentService = paymentService
        self.servicePackageService = servicePackageService
        self.scheduleService = scheduleService
        self.widgetService = widgetService
        self.scheduleFiltersService = scheduleFiltersService
        self.phoneCalling = phoneCalling
        self.favoritesService = favoritesService
    }

    public func createActivityHistoryCoordinator(
        navigationController: UINavigationController,
        navigationObserver: NavigationObserver?,
        repeatFactory: ActivityRepeatCoordinatorFactory,
        paymentsFactory: PaymentsCoordinatorFactory,
        workoutBooking: WorkoutBookingCoordinatorFactory,
        activities: [Activity]?
    ) -> ActivityHistoryCoordinator {
        let moduleInput = ActivityHistoryModuleInput(
            repeatFactory: repeatFactory,
            paymentsFactory: paymentsFactory,
            workoutBooking: workoutBooking,
            activeAppExecutor: activeAppExecutor,
            asyncAwaitPerformer: asyncAwaitPerformer,
            analytics: analytics,
            clubService: clubService,
            clipCardsTrainerManager: clipCardsTrainerManager,
            activityService: activityService,
            externalRouter: externalRouter,
            objectivesService: objectivesService,
            toaster: toaster,
            trainerTipsService: trainerTipsService,
            trainersService: trainersService,
            paymentService: paymentService,
            servicePackageService: servicePackageService,
            scheduleService: scheduleService,
            widgetService: widgetService,
            dataStore: dataStore,
            scheduleFiltersService: scheduleFiltersService,
            phoneCalling: phoneCalling,
            favoritesService: favoritesService
        )
        let moduleFactory = MainActivityHistoryModuleFactory(moduleInput: moduleInput)
        let customActivityCoordinatorFactory = MainCustomActivityCardCoordinatorFactory(
            analytics: analytics,
            customActivityService: activityService,
            objectivesService: objectivesService,
            toaster: toaster,
            userStore: dataStore
        )

        let activityHistoryFiltersCoordinatorFactory = MainActivityHistoryFiltersCoordinatorFactory(
            analyticService: analytics,
            activityHistoryFiltersService: activityHistoryFiltersService,
            asyncAwaitPerformer: asyncAwaitPerformer,
            toaster: toaster
        )

        return MainActivityHistoryCoordinator(
            activities: activities,
            navigationController: navigationController,
            navigationObserver: navigationObserver,
            moduleFactory: moduleFactory,
            customActivityCoordinatorFactory: customActivityCoordinatorFactory,
            activityHistoryFiltersCoordinatorFactory: activityHistoryFiltersCoordinatorFactory
        )
    }
}
