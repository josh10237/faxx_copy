//
//  LoginViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20
//  Copyright © 2020 FAXX. All rights reserved.
//
import UIKit
import SCSDKLoginKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        let vlayer = CAGradientLayer()
        vlayer.frame = view.bounds
        vlayer.colors=[SnapYellow.cgColor, FaxxPink.cgColor]
        view.layer.insertSublayer(vlayer, at: 0)
        super.viewDidLoad()
        
    }
    
    // go to confirm ViewController
    private func goToLoginConfirm(_ entity: UserEntity){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "loginconfirm") as!LoginConfirmViewController
        vc.userEntity = entity
        present(vc, animated: true, completion: nil)
    }
    
    // go to main ViewController
    private func goToMain(_ entity: UserEntity){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = entity
        self.present(newViewController, animated: true, completion: nil)
    }
    
    // request UserInfo to SnapSDK.
    // If you haven't requested yet, it will jump to the SnapChat app and get auth.
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
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        SCSDKLoginClient.login(from: self, completion: { success, error in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if success {
                self.fetchSnapUserInfo({ (userEntity, error) in
                    
                    if let userEntity = userEntity {
                        DispatchQueue.main.async {
                            self.goToLoginConfirm(userEntity)
                        }
                    }
                })
            }
        })
    }
}