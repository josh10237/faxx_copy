//
//  LoadViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/17/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation
import UIKit
import SCSDKLoginKit
import SCSDKBitmojiKit

let FaxxPink = UIColor(red: 254/255, green: 175/255, blue: 163/255, alpha: 1)
let FaxxDarkPink = UIColor(red: 200/255, green: 125/255, blue: 115/255, alpha: 1)
let FaxxLightPink = UIColor(red: 255/255, green: 210/255, blue: 200/255, alpha: 1)
let SnapYellow = UIColor(red: 255/255, green: 252/255, blue: 0/255, alpha: 1)

class LoadViewController: UIViewController {
    var userEntity: UserEntity?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Try to login. If you haven't requested yet, userEntity will be nil.
        self.fetchSnapUserInfo({ (userEntity, error) in
            
            if let userEntity = userEntity {
                DispatchQueue.main.async {
                    self.goToMain(userEntity)
                }
            }
            else {
                DispatchQueue.main.async {
                    self.goToLogIn()
                }
            }
        })
    }
    private func fetchSnapUserInfo(_ completion: @escaping ((UserEntity?, Error?) -> ())){
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
    private func goToMain(_ entity: UserEntity){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = entity
        self.present(newViewController, animated: true, completion: nil)
    }
    
    private func goToLogIn(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "login") as!MainViewController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }
}
