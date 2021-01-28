//
//  ProfileViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/20/20.
//  Copyright © 2020 FAXX. All rights reserved.
//

import Foundation
import SCSDKLoginKit

class ProfileViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var avatarImageView: UIImageView!
//    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var displayName: UITextField!
    
//    @IBOutlet weak var mainScore: UILabel!
//    @IBOutlet weak var numOneBest: UIImageView!
//
//    @IBOutlet weak var numTwoBest: UIImageView!
//
//    @IBOutlet weak var numThreeBest: UIImageView!
//
//    @IBOutlet weak var numFourBest: UIImageView!
//
//    @IBOutlet weak var numFiveBest: UIImageView!
//
//    @IBOutlet weak var scoreOne: UILabel!
//
//    @IBOutlet weak var scoreFour: UILabel!
//
//    @IBOutlet weak var scoreThree: UILabel!
//
//    @IBOutlet weak var scoreFive: UILabel!
//    @IBOutlet weak var scoreTwo: UILabel!
    @IBOutlet weak var firstBar: UIImageView!
    @IBOutlet weak var secondBar: UIImageView!
    @IBOutlet weak var thirdBar: UIImageView!
    @IBOutlet weak var fourthBar: UIImageView!
    @IBOutlet weak var fifthBar: UIImageView!
    @IBOutlet weak var sixthBar: UIImageView!
    @IBOutlet weak var seventhBar: UIImageView!
    
    var externalID = ""
    var avatarURL = ""
    var myDispName = ""
    var userEntity: UserEntity?
    var OneBest = ""
    var TwoBest = ""
    var ThreeBest = ""
    var FourBest = ""
    var FiveBest = ""
    
    let screenSize: CGRect = UIScreen.main.bounds
    override func viewDidLoad() {
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        super.viewDidLoad()
        displayName.delegate = self
//        displayName.backgroundColor = UIColor(patternImage: UIImage(named: "ProfileNameBar")!)
        //self!.displayName.isUserInteractionEnabled = false
        self.addTitle(title: myDispName)
        displayName.text = myDispName
        guard let avatarString = userEntity?.avatar else { return }
//        avatarImageView.layer.cornerRadius = 70
        avatarImageView.clipsToBounds = true
        avatarImageView.load(from: avatarString)
        let frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        view.backgroundColor = UIColor.white
        
//        if bestFriendDict[0]["avatar"] as? String == nil{
//
//        } else {
//            let firstBestFriend = bestFriendDict[0]["avatar"] as! String
//            numOneBest.load(from: firstBestFriend)
//            self.numOneBest.frame = frame
//
//            let firstScore = bestFriendDict[0]["score"]
//            scoreOne.text = ("\(String(describing: firstScore!))")
//        }
//        if bestFriendDict[1]["avatar"] as? String == nil{
//
//        } else {
//            if bestFriendDict[1]["avatar"] as? String == bestFriendDict[0]["avatar"] as! String {
//
//            } else {
//            let secondBestFriend = bestFriendDict[1]["avatar"] as! String
//            numTwoBest.load(from: secondBestFriend)
//            self.numTwoBest.frame = frame
//
//            let secondScore = bestFriendDict[1]["score"]
//            scoreTwo.text = ("\(String(describing: secondScore!))")
//            }
//        }
//
//        if bestFriendDict[2]["avatar"] as? String == nil {
//
//        } else {
//        let thirdBestFriend = bestFriendDict[2]["avatar"] as! String
//        numThreeBest.load(from: thirdBestFriend)
//        self.numThreeBest.frame = frame
//
//        let thirdScore = bestFriendDict[2]["score"]
//        scoreThree.text = ("\(String(describing: thirdScore!))")
//        }
//
//        if bestFriendDict[3]["avatar"] as? String == nil{
//
//        } else {
//        let fourthBestFriend = bestFriendDict[3]["avatar"] as! String
//        numFourBest.load(from: fourthBestFriend)
//        self.numFourBest.frame = frame
//
//        let fourthScore = bestFriendDict[3]["score"]
//        scoreFour.text = ("\(String(describing: fourthScore!))")
//        }
//
//        if bestFriendDict[4]["avatar"] as? String == nil{
//
//        } else {
//        let fifthBestFriend = bestFriendDict[4]["avatar"] as! String
//        numFiveBest.load(from: fifthBestFriend)
//        self.numFiveBest.frame = frame
//
//        let fifthScore = bestFriendDict[4]["score"]
//        scoreFive.text = ("\(String(describing: fifthScore!))")
//        }
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateBars()
    }
    func animateBars() {
        
        UIView.animate(withDuration: 1, animations: {() -> Void in

        })
    }
//    func compareScores(){
//
//    }

    @IBAction func logMeOut(_ sender: Any) {
        SCSDKLoginClient.clearToken()
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "load") as! LoadViewController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }
    
     
    
    func roundRect(){
        let rectWidth:CGFloat = 100
        let rectHeight:CGFloat = 80
        // Find center of actual frame to set rectangle in middle
        let xf:CGFloat = (self.screenSize.width  - rectWidth)  / 2
        let yf:CGFloat = (self.screenSize.height - rectHeight) / 2
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        let rect = CGRect(x: xf, y: yf, width: rectWidth, height: rectHeight)
        let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: 20).cgPath
        ctx.addPath(clipPath)
        ctx.setFillColor(FaxxPink.cgColor)
        ctx.closePath()
        ctx.fillPath()
        ctx.restoreGState()

    }
    
    @IBOutlet weak var DNText: UILabel!
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let ref = Constants.refs.databaseRoot.child("UserData").child(self.externalID).child("Info")
        
        let current = displayName.text
        let set = [current: avatarURL]
        ref.setValue(set)
        if displayName.text!.count < 3 {
             print ("too few chars")
            self.view.endEditing(true)
            return true
        }
        else {
            return false
        }
    }
   // let notAllowedCharacters = "/.$[]#"

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = displayName.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        
            
        }
        
        let updateText = currentText.replacingCharacters(in: stringRange, with: string)
        
        
        if updateText.count < 13{
            DNText.textColor = UIColor.white
            DNText.text = "Display Name"
            let characters = ["#", "/", "$", "[","]", "."]
            for character in characters{
                if string == character{
                    print("This characters are not allowed")
                    return false
                }
            }
            return updateText.count < 13
        }
        else {
            print("ERROR")
            DNText.textColor = UIColor.red
            DNText.text = "Display Name cannot be more than 12 characters"
            return updateText.count < 13
        }
        
    }
    @IBAction func Notification(_ sender: Any) {
        
    }
    
    @IBAction func tOS(_ sender: Any) {
        
    }
    @IBAction func Settings(_ sender: Any) {
        
    }
    
}

