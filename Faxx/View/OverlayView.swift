//
//  OverlayView.swift
//  Faxx
//
//  Created by Gavin Jimerson on 1/14/21.
//

import Foundation
import UIKit
import SCSDKLoginKit
import SCSDKBitmojiKit

class OverlayView: UIViewController {
    
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?
    
    var externalID:String = ""
    var userEntity: UserEntity?
    var otherUserID:String = ""
    var otherUserDisplayName:String = ""
    var amIAnon = false
    var areTheyAnon = false
    
    @IBOutlet weak var revealIdentity: UIButton!
//
    @IBOutlet weak var clearConversation: UIButton!
//
    @IBOutlet weak var block: UIButton!
//
    @IBOutlet weak var blockAndReport: UIButton!
//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        print("vars")
        print(userEntity)
        print(otherUserID)
        print(externalID)
        print(amIAnon)
        print(areTheyAnon)
        if amIAnon == false {
            revealIdentity.isHidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        
        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }
        
        // setting x as 0 because we don't want users to move the frame side ways!! Only want straight up or down
        view.frame.origin = CGPoint(x: 0, y: self.pointOrigin!.y + translation.y)
        
        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
    
    @IBAction func revealIdentity(_ sender: Any) {
        print("revealIdentity")
    }
    
    @IBAction func clearConversation(_ sender: Any) {
        print("clearConversation")
        
        
    }
    
    @IBAction func block(_ sender: Any) {
        print("block")

    }
    
    @IBAction func blockAndReport(_ sender: Any) {
        print("blockAndReport")
    }
    
    
}
