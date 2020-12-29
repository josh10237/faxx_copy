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
import FirebaseMessaging
import UserNotifications
import Branch
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FirebaseManagerDelegate {
    
    // MARK: - Firebase delegate
    
    
    func onUserAdded(_ user: UserContact) {
        return
    }
    
    func onSelfStateChanged(_ state: UserContact) {
        return
    }
    
    func onMessageAdded(_ message: MockMessage) {
        return
    }
    
    func setTypingStatus(_ otherUserId: String, _ typing: Bool) {
        return
    }
    
    func updateMessage(_ message: MockMessage) {
        return
    }
   
    
    let gcmMessageIDKey = "gcm.message_id"
    
    var window: UIWindow?
    var sharedUserEntity: UserEntity!
    var closedDeepLink = false
    var deepParams: [String : AnyObject]? = nil
    var firebaseManager: FirebaseManager!
    
    var notificationSenderId: Int = 0
    var isNotificationSenderAnon: Bool = false

    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UserDefaults.standard.set(true, forKey: "Text Messages")
        UserDefaults.standard.set(true, forKey: "Photo from URL Messages")
        UserDefaults.standard.set(true, forKey: "Photo Messages")
        UserDefaults.standard.set(true, forKey: "Video Messages")
        UserDefaults.standard.synchronize()
        
        FirebaseApp.configure()
        
        self.firebaseManager = FirebaseManager()
        self.firebaseManager.delegate = self
        
        Messaging.messaging().delegate = self
        Messaging.messaging().subscribe(toTopic: "TestFaxxTopic")
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self

            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        if (Messaging.messaging().fcmToken != nil) {
            print("FCM token: \(Messaging.messaging().fcmToken ?? "")")
        }else {
           print("token was nil")
        }
        
        // if you are using the TEST key
        Branch.setUseTestBranchKey(true)
        // listener for Branch Deep Link data
        Branch.getInstance().initSession(launchOptions: launchOptions) { (params, error) in
            // do stuff with deep link data (nav to page, display content, etc)
            self.deepParams = params as? [String : AnyObject]
            if let s = (params as? [String: AnyObject]),
               let tmp = s["posterId"] as? String {
                let posterId = Int(tmp) ?? 0
                if CurrentUser != nil {
                    if posterId != CurrentUser?.id {
                        self.goToAnnonChat(posterId)
                    } else {
                        self.window?.rootViewController?.showToastMessageCenter(message: "Sorry, you cannot send yourself messages")
                    }
                } else {
                    self.closedDeepLink = true
                }
            }
        }
        return true
    }
    
    func goToAnnonChat(_ posterId: Int) {
        if let curUser = CurrentUser {
            let params = [
                "f_id": curUser.id,
                "t_id": posterId,
                "anon_id": curUser.id
            ] as [String : Any]
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            guard let url = URL(string: NetworkManager.shared.CreateContact) else {
                return
            }
           
            NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
                if ((self.window?.rootViewController?.parseResponse(response: response)) != nil) {
                    if ((self.window?.rootViewController?.parseResponse(response: response)) != nil) {
                        let contact = ContactModel(response["contact"], curUser)
                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let newChatViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
                        newChatViewController.contact = contact
                        StoryboardManager.segueToChat(with: self.sharedUserEntity, chatView: newChatViewController)
                    }
                } else {
                    let message = response["err_msg"].stringValue
                    self.window?.rootViewController?.showToastMessage(message: message)
                }
            }
        }
    }
    
    func goToNotificationChat(_ f_id: Int, _ t_id: Int, _ anon_id: Int) {
        if let curUser = CurrentUser {
            let params = [
                "f_id": f_id,
                "t_id": t_id,
                "anon_id": anon_id
            ] as [String : Any]
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            guard let url = URL(string: NetworkManager.shared.CreateContact) else {
                return
            }
           
            NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
                if ((self.window?.rootViewController?.parseResponse(response: response)) != nil) {
                    if ((self.window?.rootViewController?.parseResponse(response: response)) != nil) {
                        let contact = ContactModel(response["contact"], curUser)
                        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let newChatViewController = storyBoard.instantiateViewController(withIdentifier: "chat") as! ChatViewController
                        newChatViewController.contact = contact
                        StoryboardManager.segueToChat(with: self.sharedUserEntity, chatView: newChatViewController)
                    }
                } else {
                    let message = response["err_msg"].stringValue
                    self.window?.rootViewController?.showToastMessage(message: message)
                }
            }
        }
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
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
       
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        print(JSON(userInfo))
    }
    
    func replaceRootViewController(with vc: UIViewController) {
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
  
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Notification: basic delegate")
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
    }
 
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {

    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        //If you don't want to show notification when app is open, do something here else and make a return here.
        //Even you you don't implement this delegate method, you will not see the notification on the specified controller. So, you have to implement this delegate and make sure the below line execute. i.e. completionHandler.
        
        print("will present message")
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID(present): \(messageID)")
        }

        completionHandler([.alert, .badge, .sound])
    }

    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("received message")
//        let content = response.notification.request.content
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID(receive): \(messageID)")
        }

        // Print full message.
        let tmp = JSON(userInfo)
        let senderId = tmp["senderId"].intValue
        let isAnon = tmp["isAnon"].boolValue
        
        if let curUser = CurrentUser {
            let cur_id = curUser.id
            var anon_id = cur_id
            if isAnon {
                anon_id = senderId
            }
            self.goToNotificationChat(cur_id, senderId, anon_id)
        } else {
            self.notificationSenderId = senderId
            self.isNotificationSenderAnon = isAnon
        }
       
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")

        FCM_Token = fcmToken ?? ""
        let dataDict:[String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
}




