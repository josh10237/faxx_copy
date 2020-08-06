//
//  StoryboardManager.swift
//  SnapClient
//
//  Created by Josh Benson on 7/31/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation

class StoryboardManager {
 
    class func segueToHome(with entity: UserEntity) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
        let mainVC = newViewController.viewControllers.first as! MainViewController
        mainVC.userEntity = entity
        
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.replaceRootViewController(with: newViewController)
        

    }

}
