//
//  LoginConfirmViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit
let defaults = UserDefaults.standard
let scoreDict = defaults.dictionary(forKey: "scoreDict")

class LoginConfirmViewController: UIViewController {

    @IBOutlet weak var femaleGoButton: UIButton!
    @IBOutlet weak var maleGoButton: UIButton!
    @IBOutlet weak var nonBinaryGoButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var userEntity: UserEntity?
    var externalID = ""
    
    override func viewDidLoad() {
        let vlayer = CAGradientLayer()
        vlayer.frame = view.bounds
        vlayer.colors=[FaxxPink.cgColor, UIColor.white.cgColor]
        view.layer.insertSublayer(vlayer, at: 0)
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
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

    @IBAction func goFemale(_ sender: Any) {
        let userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID)
        userDataRefMe.child("Sex").setValue(0)
        let content = [self.userEntity?.displayName: self.userEntity?.avatar]
        userDataRefMe.child("Info").setValue(content)
        goToMain()
    }
    

    @IBAction func goMale(_ sender: Any) {
        let userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID)
        userDataRefMe.child("Sex").setValue(1)
        let content = [self.userEntity?.displayName: self.userEntity?.avatar]
        userDataRefMe.child("Info").setValue(content)
        goToMain()
    }
    
    @IBAction func goNonBinary(_ sender: Any) {
        let userDataRefMe = Constants.refs.databaseRoot.child("UserData").child(self.externalID)
        userDataRefMe.child("Sex").setValue(2)
        let content = [self.userEntity?.displayName: self.userEntity?.avatar]
        userDataRefMe.child("Info").setValue(content)
        goToMain()
    }
}
