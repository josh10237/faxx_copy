//
//  LoginConfirmViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit
let defaults = UserDefaults.standard
var scoreDict: [String:Int] = defaults.dictionary(forKey: "scoreDict") as? [String:Int] ?? [:]
let hasLoggedInBefore = defaults.bool(forKey: "hasLoggedInBefore")

//var strings: [String:String] = userDefaults.object(forKey: "myKey") as? [String:String] ?? [:]

class LoginConfirmViewController: UIViewController {

    @IBOutlet weak var femaleGoButton: UIButton!
    @IBOutlet weak var maleGoButton: UIButton!
    @IBOutlet weak var nonBinaryGoButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var userEntity: UserEntity?
    var externalID = ""
    var firebaseManager = FirebaseManager()
    
    override func viewDidLoad() {
        let vlayer = CAGradientLayer()
        vlayer.frame = view.bounds
        vlayer.colors=[FaxxPink.cgColor, UIColor.white.cgColor]
        view.layer.insertSublayer(vlayer, at: 0)
        self.externalID = getExtenalId(self.userEntity?.externalID ?? "")
        super.viewDidLoad()
        
        let wlcm = "Hi " + String((userEntity?.displayName)!) + "!"
        nameLabel.text = wlcm
        
        
        // set Image
        let avatarString = userEntity?.avatar ?? DefaultAvatarUrl
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
        saveUser("Female")
    }
    

    @IBAction func goMale(_ sender: Any) {
        saveUser("Male")
    }
    
    @IBAction func goNonBinary(_ sender: Any) {
        saveUser("Other")
    }
    
    func saveUser(_ gender: String) {
        UserGender = gender
        let content = [
            "DisplayName": self.userEntity?.displayName ?? "",
            "Avatar": self.userEntity?.avatar ?? DefaultAvatarUrl,
            "Sex": gender,
            "Age": 1000,
            "FCM_Token": FCM_Token
        ] as [String : Any]
        firebaseManager.updateUser(self.externalID, content)
        
        goToMain()
    }
}
