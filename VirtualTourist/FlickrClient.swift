//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Stella Su on 2/9/16.
//  Copyright © 2016 Million Stars, LLC. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import SystemConfiguration

class FlickrClient: NSObject {

    /* Shared session */
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - GET request
    
    func taskForGETMethodWithParameters(parameters: [String : AnyObject],
        completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
            
            // Set the URL and URL request
            let urlString = Constants.BaseURL + FlickrClient.escapedParameters(parameters)
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            // Make the request
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                // Parse the received data
                if let error = downloadError {
                    let newError = FlickrClient.errorForResponse(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    FlickrClient.parseJSONWithCompletionHandler(data!, completionHandler: completionHandler)
                }
            }
            
            task.resume()
    }
    
    func taskForGETMethod(urlString: String,
        completionHandler: (result: NSData?, error: NSError?) -> Void) {
            
            // Create the request
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            
            // Make the request
            let task = session.dataTaskWithRequest(request) {
                data, response, downloadError in
                
                if let error = downloadError {
                    
                    let newError = FlickrClient.errorForResponse(data, response: response, error: error)
                    completionHandler(result: nil, error: newError)
                } else {
                    
                    completionHandler(result: data, error: nil)
                }
            }
            
            task.resume()
    }
    
    // MARK: - Helpers
    
    //  Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    // Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError?
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            
            completionHandler(result: nil, error: error)
        } else {
            
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            if(!key.isEmpty) {
                /* Make sure that it is a string value */
                let stringValue = "\(value)"
                
                /* Escape it */
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                /* Append it */
                urlVars += [key + "=" + "\(escapedValue!)"]
            }
            
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // Get error for response
    class func errorForResponse(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)) as? [String : AnyObject] {
            
            if let status = parsedResult[JSONResponseKeys.Status]  as? String,
                message = parsedResult[JSONResponseKeys.Message] as? String {
                    
                    if status == JSONResponseValues.Fail {
                        
                        let userInfo = [NSLocalizedDescriptionKey: message]
                        
                        return NSError(domain: "Virtual Tourist Error", code: 1, userInfo: userInfo)
                    }
            }
        }
        return error
    }
    
    // MARK: - Show error alert
    func showAlert(message: NSError, viewController: AnyObject) {
        let errMessage = message.localizedDescription
        
        let alert = UIAlertController(title: nil, message: errMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { action in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func openURL(urlString: String) {
        let url = NSURL(string: urlString)
        UIApplication.sharedApplication().openURL(url!)
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }


}
