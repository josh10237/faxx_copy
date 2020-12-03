//
//  LoadViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import UIKit
import SCSDKLoginKit
import SCSDKBitmojiKit
import SwiftGifOrigin

let FaxxPink = UIColor(red: 254/255, green: 175/255, blue: 163/255, alpha: 1)
let FaxxDarkPink = UIColor(red: 200/255, green: 125/255, blue: 115/255, alpha: 1)
let FaxxLightPink = UIColor(red: 255/255, green: 210/255, blue: 200/255, alpha: 1)
let SnapYellow = UIColor(red: 255/255, green: 252/255, blue: 0/255, alpha: 1)

class LoadViewController: UIViewController {
    
    @IBOutlet weak var imgLoad: UIImageView!
    
    var userEntity: UserEntity?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var firebaseManager: FirebaseManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imgLoad.loadGif(name: "fax_animation")
        
        firebaseManager = FirebaseManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Try to login. If you haven't requested yet, userEntity will be nil.
        self.fetchSnapUserInfo({ (userEntity, error) in
            if let userEntity = userEntity {
                self.appDelegate.sharedUserEntity = userEntity
                DispatchQueue.main.async {
                    if self.appDelegate.closedDeepLink {
                        self.appDelegate.closedDeepLink = false
                        if let s = self.appDelegate.deepParams,
                            let posterId = s["user"] as? String,
                            let posterName = s["displayName"] as? String,
                            let avatar = s["avatar"] as? String,
                            let fcm_token = s["fcm_token"] as? String,
                            let gender = s["gender"] as? String {
                            
                            let externalID = getExtenalId(userEntity.externalID ?? "")
                            let user_info = [
                                "DisplayName": userEntity.displayName ?? "",
                                "Avatar": userEntity.avatar ?? DefaultAvatarUrl,
                                "FCM_Token": FCM_Token,
                                "Sex": UserGender ?? "Other",
                                "Age": 1000
                                ] as [String : Any]
                            
                            let poster_info = [
                                "DisplayName": posterName,
                                "Avatar": avatar,
                                "FCM_Token": fcm_token,
                                "Sex": gender,
                                "Age": 1000
                                ] as [String : Any]
                            
                            self.firebaseManager.setAnonUser(externalID, posterId, user_info, poster_info)
                            
                            self.appDelegate.goToAnnonChat(posterId, posterName, fcm_token, avatar)
                        } else {
                            self.goToLogIn()
                        }
                    } else if self.appDelegate.notificationSenderId != "" {
                        let externalId = getExtenalId(userEntity.externalID ?? "")
                        self.firebaseManager.getNotificationSender(externalId, self.appDelegate.notificationSenderId) { (result) in
                            self.appDelegate.goToNotificationChat(self.appDelegate.notificationSenderId, result, self.appDelegate.isNotificationSenderAnon)
                        }
                    } else {
                        self.goToMain(userEntity)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.goToLogIn()
                }
            }
        })
    }
    
    func fetchSnapUserInfo(_ completion: @escaping ((UserEntity?, Error?) -> ())) {
        let graphQLQuery = "{me{displayName, externalId, bitmoji{avatar}}}"
        
        SCSDKLoginClient
            .fetchUserData(
                withQuery: graphQLQuery,
                variables: nil,
                success: { userInfo in
                    
                    if let userInfo = userInfo,
                        let data = try? JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted),
                        let userEntity = try? JSONDecoder().decode(UserEntity.self, from: data) {
                        completion(userEntity, nil)
                    }
            }) { (error, isUserLoggedOut) in
                completion(nil, error)
        }
    }
    
    private func goToMain(_ entity: UserEntity) {
        StoryboardManager.segueToHome(with: entity)
    }
    
    
    private func goToLogIn() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "login") as! LoginViewController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }
    
}
