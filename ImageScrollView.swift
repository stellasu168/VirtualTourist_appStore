//
//  ImageScrollView.swift
//  VirtualTourist
//
//  Created by Stella Su on 3/13/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit

class ImageScrollView: UIViewController, UIScrollViewDelegate {


    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var myImageView: UIImageView!
    
    var selectedImage: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("The selected image is: \(selectedImage)")
        
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 6.0
    
    }
    
    // Implement the delegate method for the scroll view
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
       
        return myImageView
    }

    
    override func viewWillAppear(animated: Bool) {
     super.viewWillAppear(animated)
        
        // ToDo: I should probably list the title of the image
        let imageUrl = NSURL(string:self.selectedImage)
        let imageData = NSData(contentsOfURL: imageUrl!)
        if (imageData != nil)
        {
            self.myImageView.image  = UIImage(data: imageData!)
        }
        
    }
  
    
    
 }
