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
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var displayName: UITextField!
    
    @IBOutlet weak var mainScore: UILabel!
    @IBOutlet weak var numOneBest: UIImageView!
    
    @IBOutlet weak var numTwoBest: UIImageView!
    
    @IBOutlet weak var numThreeBest: UIImageView!
    
    @IBOutlet weak var numFourBest: UIImageView!
    
    @IBOutlet weak var numFiveBest: UIImageView!
    
    @IBOutlet weak var scoreOne: UILabel!
    
    @IBOutlet weak var scoreFour: UILabel!
    
    @IBOutlet weak var scoreThree: UILabel!
    
    @IBOutlet weak var scoreFive: UILabel!
    @IBOutlet weak var scoreTwo: UILabel!
    var externalID = ""
    var avatarURL = ""
    var myDispName = ""
    var userEntity: UserEntity?
    
    let screenSize: CGRect = UIScreen.main.bounds
    override func viewDidLoad() {
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        super.viewDidLoad()
        displayName.delegate = self
        displayName.backgroundColor = UIColor(patternImage: UIImage(named: "ProfileNameBar")!)
        //self!.displayName.isUserInteractionEnabled = false
        self.addTitle(title: myDispName)
        
        guard let avatarString = userEntity?.avatar else { return }
        
       // avatarImageView.layer.borderColor = FaxxDarkPink.cgColor
       // avatarImageView.layer.backgroundColor = FaxxLightPink.cgColor
       // avatarImageView.layer.borderWidth = 5
        avatarImageView.layer.cornerRadius = 70
        //avatarImageView.layer.frame =
        avatarImageView.clipsToBounds = true
        avatarImageView.load(from: avatarString)
        
//        let backSplashLayer = CALayer()
//        let rectWidth:CGFloat = 300
//        let rectHeight:CGFloat = 350
//        let xf:CGFloat = (self.screenSize.width  - rectWidth)  / 2
//        let yf:CGFloat = (self.screenSize.height - rectHeight) / 5
//        let backSplashRectFrame: CGRect = CGRect(x: xf, y: yf, width: rectWidth, height: rectHeight)
//        backSplashLayer.cornerRadius = 25
//        backSplashLayer.frame = backSplashRectFrame
//        backSplashLayer.backgroundColor = FaxxPink.cgColor
//        view.layer.insertSublayer(backSplashLayer, at: 0)
//        
        
//        for h in 1...3 {
//            let boxLayer = CALayer()
//            let rectWidth1:CGFloat = 225
//            let rectHeight1:CGFloat = 40
//            let xpos:CGFloat = (self.screenSize.width  - rectWidth1)  / 2
//            let l:CGFloat = (self.screenSize.height  - rectHeight1)  / 2
//            let ypos:CGFloat = l - 150 + (CGFloat(h) * 65)
//            boxLayer.borderColor = FaxxDarkPink.cgColor
//            boxLayer.borderWidth = 3
//            let boxRectFrame: CGRect = CGRect(x: xpos, y: ypos, width: rectWidth1, height: rectHeight1)
//            boxLayer.cornerRadius = 15
//            boxLayer.frame = boxRectFrame
//            boxLayer.backgroundColor = FaxxLightPink.cgColor
//            view.layer.insertSublayer(boxLayer, at: 1)
//        }
            
        view.backgroundColor = UIColor.white

    }

    @IBAction func logMeOut(_ sender: Any) {
        SCSDKLoginClient.clearToken()
        let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "load") as! LoadViewController
        newViewController.modalPresentationStyle = .fullScreen
        self.present(newViewController, animated: true, completion: nil)
    }
//    @IBAction func addGwen(_ sender: Any) {
//        let d = String(Int(Date().timeIntervalSinceReferenceDate))
//        let ref1 = Constants.refs.databaseRoot.child(self.externalID).child("gLB5qtBQtng8qu8yICRiZ23SB8KBh4mu9bJVTev+fo").childByAutoId()
//        let message = ["sender_id": "jFF65mp1bb4lMGIRkye8Gmuab18EMfHi27z9GhfzOo", "text": "text", "time": d] as [String : Any]
//        ref1.setValue(message)
//        let ref2 = Constants.refs.databaseRoot.child(self.externalID).child("gLB5qtBQtng8qu8yICRiZ23SB8KBh4mu9bJVTev+fo").childByAutoId()
//        let message2 = ["sender_id": "gLB5qtBQtng8qu8yICRiZ23SB8KBh4mu9bJVTev", "text": "text", "time": d] as [String : Any]
//        ref2.setValue(message2)
//    }
    
    
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
        let ref = Constants.refs.databaseRoot.child(self.externalID).child("Info")
        
        let current = displayName.text
        let set = [current: avatarURL]
        ref.setValue(set)
        return true
    }
    let notAllowedCharacters = "/.$[]#"

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let currentText = displayName.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        
            
        }
        
        let updateText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if updateText.count < 12{
            DNText.textColor = UIColor.white
            DNText.text = "Display Name"
            let characters = ["#", "/", "$", "[","]", "."]
            for character in characters{
                if string == character{
                    print("This characters are not allowed")
                    return false
                }
            }
            return updateText.count < 12
        }
        else {
            print("ERROR")
            DNText.textColor = UIColor.red
            DNText.text = "Display Name cannot be more than 11 characters"
            return updateText.count < 12
        }
        
    }
    @IBAction func Notification(_ sender: Any) {
        
    }
    
    @IBAction func tOS(_ sender: Any) {
        
    }
    
}
