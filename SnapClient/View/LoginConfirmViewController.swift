//
//  LoginConfirmViewController.swift
//  SnapClient
//
//  Created by Kei Fujikawa on 2018/07/01.
//  Copyright © 2018年 Kboy. All rights reserved.
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
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }

    @IBAction func goButtonTapped(_ sender: Any) {
        goToMain()
    }
    
}
