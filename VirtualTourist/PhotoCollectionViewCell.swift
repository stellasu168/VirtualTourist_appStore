//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/23/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photoView: UIImageView!
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
        
        if photoView.image == nil {
            activityIndicator.startAnimating()
        }
    }

}
