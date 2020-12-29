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
                self.updateUser()
            } else {
                DispatchQueue.main.async {
                    self.goToLogIn()
                }
            }
        })
    }
    
    func updateUser() {
        if let entry = self.appDelegate.sharedUserEntity {
            let externalID = getExtenalId(entry.externalID ?? "")
            let params = [
                "externalId": externalID,
                "display_name": entry.displayName ?? "",
                "avatar": entry.avatar ?? DefaultAvatarUrl,
                "gender": UserGender ?? "Female",
                "age": 1000,
                "fcm_token": FCM_Token
            ] as [String : Any]
            
            if !NetworkManager.shared.isConnectedNetwork() {
                return
            }
            
            guard let url = URL(string: NetworkManager.shared.UpdateUser) else {
                return
            }
           
            NetworkManager.shared.postRequest(url: url, headers: nil, params: params) { (response) in
                if self.parseResponse(response: response) {
                    let user = response["user"]
                    CurrentUser = UserContact(user)
                    
                    DispatchQueue.main.async {
                        if self.appDelegate.closedDeepLink {
                            self.appDelegate.closedDeepLink = false
                            if let s = self.appDelegate.deepParams,
                                let tmp = s["posterId"] as? String {
                                let posterId = Int(tmp) ?? 0
                                self.appDelegate.goToAnnonChat(posterId)
                            } else {
                                self.goToMain(entry)
                            }
                        } else if self.appDelegate.notificationSenderId != 0 {
                            let senderId = self.appDelegate.notificationSenderId
                            let isAnon = self.appDelegate.isNotificationSenderAnon
                            if let curUser = CurrentUser {
                                let cur_id = curUser.id
                                var anon_id = cur_id
                                if isAnon {
                                    anon_id = senderId
                                }
                                self.appDelegate.goToNotificationChat(cur_id, senderId, anon_id)
                            }
                        } else {
                            self.goToMain(entry)
                        }
                    }
                } else {
                    let message = response["err_msg"].stringValue
                    self.showToastMessage(message: message)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.goToLogIn()
                    }
                }
            }
        } else {
            self.goToLogIn()
        }
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
