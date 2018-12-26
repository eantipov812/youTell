//
//  ViewController.swift
//  youTell
//
//  Created by Egor Antipov on 12/25/18.
//  Copyright © 2018 Egor Antipov. All rights reserved.
//

import UIKit
import VisualRecognitionV3

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    var classificationResults : [String] = []
    var confidence: [Double] = []
    
    // Initialize constants - API Key, Watson URL
    let apiKey = "25ESV2meG8icq4NmUSO1K0uBtT0rmdbJ974zbBlm6NzE"
    let version = "2018-12-25"
    let watsonURL = "https://gateway.watsonplatform.net/visual-recognition/api"
    
    // Initialize Image Picker
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Let's see!"
        imagePicker.delegate = self
        
    }

    // Get and classify image function
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
            imagePicker.dismiss(animated: true, completion: nil)
            let visualRecognition = VisualRecognition(version: version, apiKey: apiKey)
            
            visualRecognition.classify(image: image) { (classifiedImage, watsonError) in
                if watsonError != nil {
                    print("Error with classification!")
                } else {
                    
                    let classes = classifiedImage?.result?.images.first?.classifiers.first?.classes
                    
                    // Loop through classes and get classified images
                    if let classes = classes {
                        for index in 0..<classes.count {
                            self.classificationResults.append(classes[index].className)
                            self.confidence.append(classes[index].score)
                        }
                    }
                }
            }
            }
        }
    
    
    @IBAction func barButtonPressed(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }

}
