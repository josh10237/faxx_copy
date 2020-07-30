//
//  AppDelegate.swift
//  SnapClient
//
//  Created by Kei Fujikawa on 2018/06/15.
//  Copyright © 2018年 Kboy. All rights reserved.
//

import UIKit
import SCSDKLoginKit
import Firebase
import Branch

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var sharedUserEntity: UserEntity!
    var closedDeepLink = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        // if you are using the TEST key
         Branch.setUseTestBranchKey(true)
         // listener for Branch Deep Link data
         Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
        // do stuff with deep link data (nav to page, display content, etc)
            let s = (params as? [String: AnyObject])
            print("POSTERS USER ID")
            print(s!["user"] as Any)
            if s!["user"] != nil {
                let posterID = (s!["user"]) as! String
                print("POSTER ID")
                print(posterID)
                if #available(iOS 13.0, *) {
                    let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                    if keyWindow != nil {
                        if var topController = keyWindow?.rootViewController {
                            while let presentedViewController = topController.presentedViewController {
                                topController = presentedViewController
                            }
                            
                            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                            let newViewController = storyBoard.instantiateViewController(identifier: "chat") as!ChatViewController
                            newViewController.modalPresentationStyle = .fullScreen

                            if self.sharedUserEntity != nil {
                                newViewController.userEntity = self.sharedUserEntity
                                newViewController.otherUserID = posterID
                                topController.present(newViewController, animated: true, completion: nil)
                            } else {
                                self.closedDeepLink = true
                            }
                        }
                    }

                }
            }
        }
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
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
    

}

