//
//  AppDelegate.swift
//  SnapClient
//
//  Created by Josh Benson on 2020/06/15.
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit
import SCSDKLoginKit
import Firebase
import FirebaseCore
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sharedUserEntity: UserEntity!
    var closedDeepLink = false

    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        // if you are using the TEST key
         Branch.setUseTestBranchKey(true)
         // listener for Branch Deep Link data
         Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
        // do stuff with deep link data (nav to page, display content, etc)
            let s = (params as? [String: AnyObject])
            if s!["user"] != nil {
                let posterID = (s!["user"]) as! String
                print("loc 10")
                print(posterID)
                print(self.sharedUserEntity)
                let externalID = String((self.sharedUserEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
                let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if keyWindow != nil {
                    print("loc 11")
                    if var topController = keyWindow?.rootViewController {
                        while let presentedViewController = topController.presentedViewController {
                            topController = presentedViewController
                        }

                        if self.sharedUserEntity != nil {
                            let userDataRefMe = Constants.refs.databaseRoot.child("UserData").child("ZAAAAA3AAAAAZ" + externalID).child(posterID)
                            let userDataRefThem = Constants.refs.databaseRoot.child("UserData").child(posterID).child("ZAAAAA3AAAAAZ" + externalID)
                            let d = Int(Date().timeIntervalSinceReferenceDate)
                            let query1 = Constants.refs.databaseRoot.child("UserData").child(posterID).child("Info").queryLimited(toFirst: 1)
                            _ = query1.observe(.childAdded, with: { [weak self] snapshot in
                                print("A!1")
                                print(snapshot)
                                //add their info to my user data
                                let theirInfoAvatar = snapshot.value
                                let theirInfoDisplayName = snapshot.key
                                print("llm")
                                let content = ["Info": [theirInfoDisplayName: theirInfoAvatar], "isNew": false, "time": d] as [String : Any]
                                print(content)
                                userDataRefMe.setValue(content)
                            })
                            
//                            add my info with anon delimiter to their info
                            let content = ["Info": ["DisplayName": "Anon", "Avatar": "AnonAvatarURL", "Sex": 0, "Age": 1000], "isNew": true, "time": d] as [String : Any]
                            userDataRefThem.setValue(content)
                            
//                            StoryboardManager.segueToChatDeepLink(entity: self.sharedUserEntity, posterID: posterID, externalID: externalID)
                            
                            
//                            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                            let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
//                            newViewController.userEntity = self.sharedUserEntity
//                            newViewController.goToChat(otherUserId: posterID, otherUserDisplayName: "Poster Display", amIAnon: true)
//                            newViewController.modalPresentationStyle = .fullScreen
//                            print("LOCFIND")
//                            print(newViewController)
//                            print(topController)
//                            topController.present(newViewController, animated: true, completion: nil)
                            
                            //TODO: Link to a page where nav controller is created (or available) then from there call nav to chat with correct parameters
//                            let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
//                            let newViewController = storyBoard.instantiateViewController(withIdentifier: "load") as!LoadViewController
//                            newViewController.userEntity = self.sharedUserEntity
//                            newViewController.goToChat(otherUserId: posterID, otherUserDisplayName: "Poster Display", amIAnon: true)
//                            newViewController.modalPresentationStyle = .fullScreen
//                            print("LOCFIND")
//                            print(newViewController)
//                            print(topController)
//                            topController.present(newViewController, animated: true, completion: nil)
                            
                            
                            
                            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let mainNavigationVC = storyBoard.instantiateViewController(withIdentifier: "MainNavigationController") as! UINavigationController

                            let newChatViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
                            newChatViewController.amIAnon = true
                            newChatViewController.areTheyAnon = false
                            newChatViewController.userEntity = self.sharedUserEntity
                            newChatViewController.otherUserID = posterID
                            
                            mainNavigationVC.present(newChatViewController, animated: true, completion: nil)
//
//                            newViewController.externalID = externalID
//                            newViewController.otherUserDisplayName = "posterID" //TODO: Query for disp name from server
//                            topController.present(newViewController, animated: true, completion: nil)
                            //TODO FIx bug with deep link chat screen
                            //topController.navigationController?.pushViewController(newViewController, animated: true)
                            //Get your own display name
//                            ref = Constants.refs.databaseRoot.child(externalID).childByAutoId()
//                            ref = Constants.refs.databaseRoot.child(externalID).child(posterID).childByAutoId()
//                            ref = Constants.refs.databaseRoot.child(posterID).child(anonID).childByAutoId()
                            
                            
                        } else {
                            self.closedDeepLink = true
                        }
                    }
                }
            }
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let s = SCSDKLoginClient.application(app, open: url, options: options)
        if (!s){
            return Branch.getInstance().application(app, open: url, options: options)
        }
        else{
            return s
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
      // handler for Universal Links
        return Branch.getInstance().continue(userActivity)
    }
    
    
    
   

    

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
      // handler for Push Notifications
      Branch.getInstance().handlePushNotification(userInfo)
    }
    
    func replaceRootViewController(with vc: UIViewController) {
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    

}

