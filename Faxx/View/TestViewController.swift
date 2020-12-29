//
//  TestViewController.swift
//  Faxx
//
//  Created by Raul Cheng on 12/21/20.
//

import UIKit

class TestViewController: UIViewController {
    
    @IBAction func onBack(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
