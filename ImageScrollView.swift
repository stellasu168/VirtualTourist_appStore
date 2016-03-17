//
//  ImageScrollView.swift
//  VirtualTourist
//
//  Created by Stella Su on 3/13/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit

class ImageScrollView: UIViewController {


    @IBOutlet weak var myImageView: UIImageView!
    
    var selectedImage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(selectedImage)
    
    }
    
    override func viewWillAppear(animated: Bool) {
     super.viewWillAppear(animated)
        let imageUrl = NSURL(string:self.selectedImage)
        let imageData = NSData(contentsOfURL: imageUrl!)
        if (imageData != nil)
        {
            self.myImageView.image  = UIImage(data: imageData!)
        }
        
    }
    
    
    
 }
