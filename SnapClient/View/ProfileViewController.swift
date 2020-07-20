//
//  ProfileViewController.swift
//  SnapClient
//
//  Created by Josh Benson on 7/20/20.
//  Copyright © 2020 Kboy. All rights reserved.
//

import Foundation

class ProfileViewController: UIViewController{
    @IBOutlet weak var avatarImageView: UIImageView!
    var userEntity: UserEntity?
    let screenSize: CGRect = UIScreen.main.bounds
    override func viewDidLoad() {
    super.viewDidLoad()
    let barLayer = CALayer()
    let rectFrame: CGRect = CGRect(x:CGFloat(0), y:CGFloat(0), width:CGFloat(screenSize.width), height:CGFloat(100))
    barLayer.frame = rectFrame
    barLayer.backgroundColor = FaxxPink.cgColor
    view.layer.insertSublayer(barLayer, at: 0)
        
    let image = UIImage(named: "leftarrow_ICON")
    let backbutton = UIButton(type: UIButton.ButtonType.custom)
    backbutton.frame = CGRect(x: 100, y: 100, width: 200, height: 100)
    backbutton.setImage(image, for: .normal)
    backbutton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
    backbutton.frame = CGRect(origin: CGPoint(x: 20, y: 50), size: CGSize(width:25,height: 25))
    self.view.addSubview(backbutton)
    
    guard let avatarString = userEntity?.avatar else { return }
    avatarImageView.load(from: avatarString)
    let backSplashLayer = CALayer()
    let rectWidth:CGFloat = 300
    let rectHeight:CGFloat = 450
    let xf:CGFloat = (self.screenSize.width  - rectWidth)  / 2
    let yf:CGFloat = (self.screenSize.height - rectHeight) / 2
    let backSplashRectFrame: CGRect = CGRect(x: xf, y: yf, width: rectWidth, height: rectHeight)
    backSplashLayer.cornerRadius = 25
    backSplashLayer.frame = backSplashRectFrame
    backSplashLayer.backgroundColor = FaxxPink.cgColor
    view.layer.insertSublayer(backSplashLayer, at: 1)

    }
    
    
    @objc func backPressed() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "main") as!MainViewController
        newViewController.userEntity = userEntity
        newViewController.modalPresentationStyle = .fullScreen
        newViewController.modalPresentationStyle = .custom
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
}
