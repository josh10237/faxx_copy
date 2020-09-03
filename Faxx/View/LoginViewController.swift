//
//  LoginViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20
//  Copyright © 2020 FAXX. All rights reserved.
//
import UIKit
import SCSDKLoginKit
//import SwiftGifOrigin


class LoginViewController: UIViewController {
    @IBOutlet weak var gifImage: UIImageView!
    
    override func viewDidLoad() {
//        let vlayer = CAGradientLayer()
//        vlayer.frame = view.bounds
//        vlayer.colors=[SnapYellow.cgColor, FaxxPink.cgColor]
//        view.layer.insertSublayer(vlayer, at: 0)
//        super.viewDidLoad()
//        self.gifImage.image = UIImage.gif(name: "faxx_animation")
//        self.gifImage.image = UIImage.gif(name: "faxx_animation.gif")
//        guard let confettiImageView = UIImageView.fromGif(frame: view.frame, resourceName: "faxx_animation") else { return }
        //confettiImageView.animationDuration = 3
        //confettiImageView.animationRepeatCount = 1
//        view.addSubview(confettiImageView)
//        confettiImageView.startAnimating()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
//            confettiImageView.stopAnimating()
//        })

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

extension UIImageView {
    static func fromGif(frame: CGRect, resourceName: String) -> UIImageView? {
        guard let path = Bundle.main.path(forResource: resourceName, ofType: "gif") else {
            print("Gif does not exist at that path")
            return nil
        }
        let url = URL(fileURLWithPath: path)
        guard let gifData = try? Data(contentsOf: url),
            let source =  CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
        var images = [UIImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: image))
            }
        }
        let gifImageView = UIImageView(frame: frame)
        gifImageView.animationImages = images
        return gifImageView
    }
}
