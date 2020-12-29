//
//  SelectOptionController.swift
//  Faxx
//
//  Created by Raul Cheng on 12/17/20.
//

import UIKit

protocol SelectOptionDelegate {
    func onTakePhone()
    func onChooseFromCamera()
    func onClose()
}

class SelectOptionController: UIViewController {
    
    @IBAction func onTakePhoto(_ sender: Any) {
        self.delegate?.onTakePhone()
    }
    
    @IBAction func onChooseFromCamera(_ sender: Any) {
        self.delegate?.onChooseFromCamera()
    }
    
    @IBAction func onPanGesture(_ sender: Any) {
        guard let vel = (sender as? UIPanGestureRecognizer)?.velocity(in: self.view) else { return }
        if vel.y > 0 {
            delegate?.onClose()
        }
    }
    
    var delegate: SelectOptionDelegate?
}
