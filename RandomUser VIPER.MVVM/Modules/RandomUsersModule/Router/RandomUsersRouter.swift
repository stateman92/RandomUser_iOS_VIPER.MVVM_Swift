//
//  RandomUsersRouter.swift
//  RandomUserViper
//
//  Created by Kálai Kristóf on 2020. 05. 17..
//  Copyright © 2020. Kálai Kristóf. All rights reserved.
//

import UIKit
import Hero

// MARK: - The RandomUsersModule's Router base part.
class RandomUsersRouter: RouterProtocolToPresenter {
    
    static var navigationController: UINavigationController?
    
    /// Creates and sets up the RandomUsersModule.
    static func createModule() -> RandomUsersViewController {
        
        let view = AppDelegate.mainStoryboard.instantiateViewController(withIdentifier: "RandomUsersViewController")
        
        let interactor: InteractorProtocolToPresenter = RandomUsersInteractor()
        let viewModel: RandomUsersViewModelProtocol & PresenterProtocolToInteractor = RandomUsersViewModel(interactor)
        let router: RouterProtocolToPresenter = RandomUsersRouter()
        
        (view as! RandomUsersViewController).injectViewModel(viewModel)
        viewModel.injectRouter(router)
        interactor.injectPresenter(viewModel)
        
        return view as! RandomUsersViewController
    }
    
    /// Show the details.
    func pushToRandomUserDetailsScreen(selectedUser user: User) {
        let randomUserDetailsViewController = RandomUserDetailsRouter.createModule(user: user)
        RandomUsersRouter.navigationController?.hero.isEnabled = true
        RandomUsersRouter.navigationController?.pushViewController(randomUserDetailsViewController, animated: true)
    }
}
