//
//  ProfileViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/20/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation

class ProfileViewController: UIViewController, UITextFieldDelegate{
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var displayName: UITextField!
    var externalID = ""
    var avatarURL = ""
    var userEntity: UserEntity?
    
    let screenSize: CGRect = UIScreen.main.bounds
    override func viewDidLoad() {
        self.externalID = String((self.userEntity?.externalID)!.dropFirst(6).replacingOccurrences(of: "/", with: ""))
        super.viewDidLoad()
        displayName.delegate = self
        
        let query = Constants.refs.databaseRoot.child(externalID).child("Info").queryLimited(toLast: 1)
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            let nm = String(snapshot.key)
            self!.avatarURL = snapshot.value as! String
            self!.displayName.text = nm
            //self!.displayName.isUserInteractionEnabled = false
            self!.addTitle(title: nm)
        })
        
        guard let avatarString = userEntity?.avatar else { return }
        avatarImageView.layer.borderColor = FaxxDarkPink.cgColor
        avatarImageView.layer.backgroundColor = FaxxLightPink.cgColor
        avatarImageView.layer.borderWidth = 5
        avatarImageView.layer.cornerRadius = 70
        //avatarImageView.layer.frame =
        avatarImageView.clipsToBounds = true
        avatarImageView.load(from: avatarString)
        
        let backSplashLayer = CALayer()
        let rectWidth:CGFloat = 300
        let rectHeight:CGFloat = 350
        let xf:CGFloat = (self.screenSize.width  - rectWidth)  / 2
        let yf:CGFloat = (self.screenSize.height - rectHeight) / 5
        let backSplashRectFrame: CGRect = CGRect(x: xf, y: yf, width: rectWidth, height: rectHeight)
        backSplashLayer.cornerRadius = 25
        backSplashLayer.frame = backSplashRectFrame
        backSplashLayer.backgroundColor = FaxxPink.cgColor
        view.layer.insertSublayer(backSplashLayer, at: 0)
        
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
    
    
    @objc func backPressed() {
        self.dismiss(animated: true, completion: nil)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let ref = Constants.refs.databaseRoot.child(self.externalID).child("Info")
        let current = displayName.text
        print("BEFORE")
        let set = [current: avatarURL]

        ref.setValue(set)
        print("AFTER")
        return true
    }
}
