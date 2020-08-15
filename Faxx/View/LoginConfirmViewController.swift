//
//  LoginConfirmViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit

class LoginConfirmViewController: UIViewController {

    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var userEntity: UserEntity?
    
    override func viewDidLoad() {
        let vlayer = CAGradientLayer()
        vlayer.frame = view.bounds
        vlayer.colors=[FaxxPink.cgColor, UIColor.white.cgColor]
        view.layer.insertSublayer(vlayer, at: 0)
        super.viewDidLoad()
        
        let wlcm = "Hi " + String((userEntity?.displayName)!) + "!"
        nameLabel.text = wlcm
        
        
        // set Image
        guard let avatarString = userEntity?.avatar else { return }
        avatarImageView.load(from: avatarString)
    }
    
    private func goToMain(){
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "load") as!LoadViewController
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.userEntity = userEntity
        self.present(newViewController, animated: true, completion: nil)
    }

    @IBAction func goButtonTapped(_ sender: Any) {
        goToMain()
    }
    
}
