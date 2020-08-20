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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
                print("POSTER ID")
                print(posterID)
                let externalID = String((self.sharedUserEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
                let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
                if keyWindow != nil {
                    if var topController = keyWindow?.rootViewController {
                        while let presentedViewController = topController.presentedViewController {
                            topController = presentedViewController
                        }

                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let newViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as!ChatViewController
                        newViewController.modalPresentationStyle = .fullScreen

                        if self.sharedUserEntity != nil {
                            newViewController.userEntity = self.sharedUserEntity
                            newViewController.otherUserID = posterID
                            newViewController.otherUserDisplayName = "posterID" //TODO: Query for disp name from server
                            topController.present(newViewController, animated: true, completion: nil)
                            //TODO FIx bug with deep link chat screen
                            //topController.navigationController?.pushViewController(newViewController, animated: true)
                            let anonID = "AAAAA" + externalID
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
    
    func replaceRootViewController(with vc: UIViewController) {
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    

}

