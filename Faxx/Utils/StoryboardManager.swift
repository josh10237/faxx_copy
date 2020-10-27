//
//  StoryboardManager.swift
//  SnapClient
//
//  Created by Josh Benson on 7/31/20.
//  Copyright © 2020 FAXX. All rights reserved.
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
//    class func segueToChatDeepLink(entity: UserEntity, posterID: String, externalID: String) {
//        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController
//        let chatVC = newViewController.viewControllers.first as! ChatViewController
//        chatVC.userEntity = entity
//
//        chatVC.amIAnon = true
//        chatVC.areTheyAnon = false
//        chatVC.modalPresentationStyle = .fullScreen
//
//        chatVC.userEntity = entity
//        chatVC.otherUserID = posterID
//
//        chatVC.externalID = externalID
//        chatVC.otherUserDisplayName = "posterID" //TODO: Query for disp name from server
//
//        let appDelegate = UIApplication.shared.delegate as! AppDelegate
//        appDelegate.replaceRootViewController(with: newViewController)
//
//
//    }

}
