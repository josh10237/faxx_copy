//
//  File.swift
//  SnapClient
//
//  Created by Josh Benson on 7/16/20/
//  Copyright © 2020 FAXX. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func load(from urlString: String){
        guard let imageURL = URL(string: urlString) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: imageURL)
            let image = UIImage(data: data)
            self.image = image
        } catch {
            
        }
    }
}

extension UIImage {
    
    static func load(from urlString: String) -> UIImage? {
        guard let imageURL = URL(string: urlString),
            let data = try? Data(contentsOf: imageURL) else {
                return nil
        }
        return UIImage(data: data)
    }
    
    func upOrientationImage() -> UIImage? {
        let curSize = self.size
        let imageSize = CGSize(width: curSize.width * 0.2, height: curSize.height * 0.2)
        switch imageOrientation {
        case .up:
            return self
        default:
            UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
            draw(in: CGRect(origin: .zero, size: imageSize))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return result
        }
    }
}
