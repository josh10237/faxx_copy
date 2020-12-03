//
//  StoryboardManager.swift
//  SnapClient
//
//  Created by Josh Benson on 7/31/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import UIKit

class StoryboardManager {
 
    class func segueToHome(with entity: UserEntity) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
        let mainVC = newViewController.viewControllers.first as! MainViewController
        mainVC.userEntity = entity
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.replaceRootViewController(with: newViewController)
        
    }
    
    class func segueToChat(with entity: UserEntity, chatView: ChatViewController) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
        let mainVC = newViewController.viewControllers.first as! MainViewController
        mainVC.userEntity = entity
        newViewController.viewControllers = [mainVC, chatView]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.replaceRootViewController(with: newViewController)
        
        //newViewController.pushViewController(chatView, animated: true)
        
    }

}
