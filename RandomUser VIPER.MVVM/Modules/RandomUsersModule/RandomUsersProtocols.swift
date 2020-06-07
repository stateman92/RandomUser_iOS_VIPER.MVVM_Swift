//
//  Protocols.swift
//  RandomUserViper
//
//  Created by Kálai Kristóf on 2020. 05. 17..
//  Copyright © 2020. Kálai Kristóf. All rights reserved.
//

import UIKit
import RxSwift

// MARK: - VIPER and MVVM architecture's elements.



// MVVM architecture presents a one-direct data flow, so
// - View contains ViewModel,
// - ViewModel contains Model,
// and no other containment or any other communication are not allowed.
// MARK: - ViewModel needs to implement this.
protocol RandomUsersViewModelProtocol {
    
    /// VIPER architecture.
    func injectInteractor(_ interactorProtocolToPresenter: InteractorProtocolToPresenter)
    func injectRouter(_ routerProtocolToPresenter: RouterProtocolToPresenter)
    
    /// Show the details `UIViewController`.
    func showRandomUserDetailsController(selected: Int)
    
    /// The incoming users.
    var users: BehaviorSubject<[User]> { get set }
    
    /// Whether the refresh spinner should shown or not.
    var showRefreshView: BehaviorSubject<Bool> { get set }
    
    /// Self-check, that actually distinct users are fetched.
    var numberOfDistinctNamedPeople: BehaviorSubject<Int> { get }
    
    /// Returns the so far fetched data + number of users in a page.
    var currentMaxUsers: BehaviorSubject<Int> { get }
    
    /// Fetch some random users.
    func getRandomUsers(refresh: Bool)
    
    /// Signs that the refresh animation ended.
    func endRefreshing()
}

// MARK: - Router needs to implement this (Presenter use it).
protocol RouterProtocolToPresenter {
    
    /// VIPER architecture.
    static func createModule() -> RandomUsersViewController
    
    /// Store the `UINavigationController` to be able to push the details.
    static var navigationController: UINavigationController? { get set }
    
    /// Push the details `UIViewController`.
    func pushToRandomUserDetailsScreen(selectedUser user: User)
}

// MARK: - Interactor needs to implement this (Presenter use it).
protocol InteractorProtocolToPresenter {
    
    /// VIPER architecture.
    func injectPresenter(_ presenterProtocolToInteractor: PresenterProtocolToInteractor)
    
    /// Shows whether it is busy with some network calls.
    var  isFetching: Bool { get set }
    
    /// Download random users with the given parameters.
    /// - Parameters:
    ///   - page: the page that you want to download.
    ///   - results: the number of results in a page.
    ///   - seed: the API use this to give some data. For the same seed, it gives back the same results.
    func getUsers(page: Int, results: Int, seed: String)
    
    /// Try to load the previously cached data.
    func getCachedData()
    
    /// Delete the previously cached data.
    func deleteCachedData()
}

// MARK: - Presenter needs to implement this (Interactor use it).
protocol PresenterProtocolToInteractor: class {
    
    /// Will be called if the fetch (after a new seed value) was successful.
    func didUserFetchSuccess(users: [User])
    
    /// Will be called if any error occured while the requests.
    func didUserFetchFail(errorType: ErrorTypes)
    
    /// Will be called after the cache loaded.
    func didCacheLoadFinished(_ result: Result<[User], ErrorTypes>)
}
