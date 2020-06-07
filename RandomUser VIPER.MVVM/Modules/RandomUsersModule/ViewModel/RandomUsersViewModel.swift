//
//  RandomUsersPresenter.swift
//  RandomUserViper
//
//  Created by Kálai Kristóf on 2020. 05. 17..
//  Copyright © 2020. Kálai Kristóf. All rights reserved.
//

/*
 import Foundation
 import RealmSwift
 
 // MARK: - The RandomUsersModule's Presenter base part.
 class RandomUsersViewModel {
 
 /// VIPER architecture elements.
 private var interactorProtocolToPresenter: InteractorProtocolToPresenter?
 private var routerProtocolToPresenter: RouterProtocolToPresenter?
 
 /// Number of users that will be downloaded at the same time.
 private let numberOfUsersPerPage = 10
 /// The initial seed value. Changed after all refresh / restart.
 private var seed = String.getRandomString()
 /// Returns the number of the next page.
 private var nextPage: Int {
 return users.count / numberOfUsersPerPage + 1
 }
 
 /// `RandomUserPresenterProtocol` variables part.
 
 /// The so far fetched user data.
 var users = [User]()
 }
 
 // MARK: The PresenterProtocolToInteractor part (Interactor calls this).
 extension RandomUsersViewModel: PresenterProtocolToInteractor {
 
 /// Will be called if (after a new seed value) the fetch was successful.
 func didUserFetchSuccess(users: [User]) {
 self.users.append(contentsOf: users)
 if self.users.count == numberOfUsersPerPage {
 randomUserViewProtocol?.didRandomUsersAvailable { [weak self] in
 guard let self = self else { return }
 self.interactorProtocolToPresenter?.isFetching = false
 }
 } else {
 randomUserViewProtocol?.didEndRandomUsersPaging()
 interactorProtocolToPresenter?.isFetching = false
 }
 }
 
 /// Will be called if the fetch (about paging) was successful.
 func didUserFetchFail(errorMessage: String) {
 randomUserViewProtocol?.didErrorOccuredWhileDownload(errorMessage: errorMessage)
 }
 
 /// Will be called after the cache loaded.
 func didCacheLoadFinished(_ result: Result<[User], ErrorTypes>) {
 switch result {
 case .success(let users):
 self.users.append(contentsOf: users)
 randomUserViewProtocol?.didRandomUsersAvailable { [weak self] in
 guard let self = self else { return }
 self.interactorProtocolToPresenter?.isFetching = false
 }
 case .failure(_):
 interactorProtocolToPresenter?.isFetching = false
 getRandomUsers()
 }
 }
 }
 
 // MARK: The PresenterProtocolToView part (View calls this).
 extension RandomUsersViewModel: RandomUsersViewModelProtocol {
 
 func showRandomUserDetailsController(selected: Int) {
 routerProtocolToPresenter?.pushToRandomUserDetailsScreen(selectedUser: users[selected])
 }
 
 /// Returns the so far fetched data + number of users in a page.
 /// - Note:
 /// If the number of the displayed user is greater or equal with the `users.count` but less than the `currentMaxUsers`,
 ///     the View can display a loading icon.
 var currentMaxUsers: Int {
 return nextPage * numberOfUsersPerPage
 }
 
 /// Self-check, that actually distinct users are fetched.
 /// - Note:
 /// Can be used to display somewhere.
 var numberOfDistinctNamedPeople: Int {
 Set(users.map { user -> String in
 user.fullName
 }).count
 }
 
 /// Dependency Injection via Setter Injection.
 func injectInteractor(_ interactorProtocolToPresenter: InteractorProtocolToPresenter) {
 self.interactorProtocolToPresenter = interactorProtocolToPresenter
 }
 
 /// Dependency Injection via Setter Injection.
 func injectRouter(_ routerProtocolToPresenter: RouterProtocolToPresenter) {
 self.routerProtocolToPresenter = routerProtocolToPresenter
 }
 
 /// Fetch some random users.
 func getRandomUsers() {
 interactorProtocolToPresenter?.getUsers(page: nextPage, results: numberOfUsersPerPage, seed: seed)
 }
 
 /// Fetch some new random users.
 /// - Note:
 /// Remove all so far downloaded data, recreate the seed value.
 /// Immediately calls the `randomUsersRefreshStarted()` method of the `delegate`.
 /// - Parameters:
 ///   - withDelay: the duration after the fetch starts.
 func refresh(withDelay delay: Double = 0) {
 users.removeAll()
 interactorProtocolToPresenter?.deleteCachedData()
 seed = String.getRandomString()
 randomUserViewProtocol?.willRandomUsersRefresh()
 run(delay) { [weak self] in
 guard let self = self else { return }
 self.getRandomUsers()
 }
 }
 
 /// Retrieve the previously cached users.
 func getCachedUsers() {
 interactorProtocolToPresenter?.isFetching = true
 run(1.0) { [weak self] in
 guard let self = self else { return }
 self.interactorProtocolToPresenter?.getCachedData()
 }
 }
 }*/

import Foundation
import RxRelay
import RxSwift
import RxCocoa

class RandomUsersViewModel {
    
    /// VIPER architecture elements.
    private var interactorProtocolToPresenter: InteractorProtocolToPresenter?
    private var routerProtocolToPresenter: RouterProtocolToPresenter?
    
    /// Returns the number of the next page.
    private var nextPage: Int {
        return usersArray.count / numberOfUsersPerPage + 1
    }
    /// Number of users that will be downloaded at the same time.
    private var numberOfUsersPerPage = 10
    /// The initial seed value. Changed after all refresh / restart.
    private var seed = UUID().uuidString
    /// The Rx framework's `DisposeBag` component.
    private let disposeBag = DisposeBag()
    /// The so far fetched user data.
    private var usersArray = [User]()
    
    /// The incoming users.
    var users = BehaviorSubject<[User]>.init(value: [User]())
    
    /// Whether the refresh spinner should shown or not.
    var showRefreshView = BehaviorSubject<Bool>.init(value: false)
    
    /// Self-check, that actually distinct users are fetched.
    var numberOfDistinctNamedPeople = BehaviorSubject<Int>.init(value: 0)
    
    /// Returns the so far fetched data + number of users in a page.
    var currentMaxUsers = BehaviorSubject<Int>.init(value: 10)
    
    /// Setup the Rx, and get some user data.
    init(_ interactorProtocolToPresenter: InteractorProtocolToPresenter? = nil) {
        if let interactorProtocolToPresenter = interactorProtocolToPresenter {
            self.interactorProtocolToPresenter = interactorProtocolToPresenter
        }
        users.subscribe(onNext: { [weak self] users in
            guard let self = self else { return }
            self.numberOfDistinctNamedPeople.on(.next(Set(self.usersArray.map { user -> String in
                user.fullName
            }).count))
            self.currentMaxUsers.on(.next((self.nextPage + 1) * self.numberOfUsersPerPage))
        }).disposed(by: disposeBag)
        getCachedUsers()
    }
}

extension RandomUsersViewModel: RandomUsersViewModelProtocol {
    
    /// Retrieve the previously cached users.
    private func getCachedUsers() {
        run(1.0) { [weak self] in
            guard let self = self else { return }
            self.interactorProtocolToPresenter?.getCachedData()
        }
    }
    
    /// Signs that the refresh animation ended.
    func endRefreshing() {
        interactorProtocolToPresenter?.isFetching = false
    }
    
    func showRandomUserDetailsController(selected: Int) {
        routerProtocolToPresenter?.pushToRandomUserDetailsScreen(selectedUser: usersArray[selected])
    }
    
    /// Fetch some random users.
    /// - Parameters:
    ///   - refresh: whether the user wants a full refresh or just more data.
    func getRandomUsers(refresh: Bool = false) {
        showRefreshView.on(.next(true))
        
        if refresh {
            seed = UUID().uuidString
            usersArray.removeAll()
            interactorProtocolToPresenter?.deleteCachedData()
            users.on(.next([User]()))
            run(0.33) {
                self.interactorProtocolToPresenter?.getUsers(page: self.nextPage, results: self.numberOfUsersPerPage, seed: self.seed)
            }
        } else {
            self.interactorProtocolToPresenter?.getUsers(page: self.nextPage, results: self.numberOfUsersPerPage, seed: self.seed)
        }
    }
    
    /// Dependency Injection via Setter Injection.
    func injectInteractor(_ interactorProtocolToPresenter: InteractorProtocolToPresenter) {
        self.interactorProtocolToPresenter = interactorProtocolToPresenter
    }
    
    /// Dependency Injection via Setter Injection.
    func injectRouter(_ routerProtocolToPresenter: RouterProtocolToPresenter) {
        self.routerProtocolToPresenter = routerProtocolToPresenter
    }
}

// MARK: The PresenterProtocolToInteractor part (Interactor calls this).
extension RandomUsersViewModel: PresenterProtocolToInteractor {
    
    /// Will be called if (after a new seed value) the fetch was successful.
    func didUserFetchSuccess(users: [User]) {
        showRefreshView.on(.next(false))
        if usersArray.count != 0 {
            interactorProtocolToPresenter?.isFetching = false
        }
        usersArray.append(contentsOf: users)
        self.users.on(.next(self.usersArray))
    }
    
    /// Will be called if the fetch (about paging) was successful.
    func didUserFetchFail(errorType: ErrorTypes) {
        showRefreshView.on(.next(false))
        users.on(.error(errorType))
    }
    
    /// Will be called after the cache loaded.
    func didCacheLoadFinished(_ result: Result<[User], ErrorTypes>) {
        switch result {
        case .success(let users):
            usersArray.append(contentsOf: users)
            self.users.on(.next(self.usersArray))
        case .failure(_):
            interactorProtocolToPresenter?.isFetching = false
            getRandomUsers()
        }
    }
}
