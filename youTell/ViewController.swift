//
//  ViewController.swift
//  youTell
//
//  Created by Egor Antipov on 12/25/18.
//  Copyright © 2018 Egor Antipov. All rights reserved.
//

import UIKit
import VisualRecognitionV3
import AVFoundation
import Alamofire
import SwiftyJSON
import LanguageTranslatorV3

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var newWordButton: UIBarButtonItem!
    @IBOutlet weak var barButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var listenInLabel: UILabel!
    @IBOutlet weak var languagePickerView: UIPickerView!
    @IBOutlet weak var listenButton: UIButton!
    
    // Define Available Languages
    let languages = ["Eng", "Rus", "Esp"]
    
    var classificationResults : [String] = []
    var confidence: [Double] = []
    
    // Initialize constants - API Key, Watson URL
    let apiKey = Constants.apiKey
    let version = Constants.version
    let watsonURL = Constants.watsonURL
    
    let translationAPIKey = Constants.translationAPIKey
    let translationURL = Constants.translationURL
    
    // Initialize Synthesizer
    let synthesizer = AVSpeechSynthesizer()
    
    // Initialize Image Picker
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set delegate and data source for the picker view
        languagePickerView.dataSource = self
        languagePickerView.delegate = self
        
        // Update Title
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
                    
                    DispatchQueue.main.sync {
                        // Add the recognized image and the confidence to the labels
                        self.wordLabel.text = self.classificationResults[0]
                        self.confidenceLabel.text = (String(self.confidence[0] * 100) + "%")
                        
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
    
    
    @IBAction func newWordButtonPressed(_ sender: Any) {
        
    }
    
    
    @IBAction func listenButtonPressed(_ sender: Any) {
        // Implement the method to hear the word
        let string_word = "Hello, the word is " + wordLabel.text!
        let utterance = AVSpeechUtterance(string: string_word)
        utterance.rate = 0.4
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
        
        /*
        let language_translator = LanguageTranslator(version: "Version1", apiKey: "L3JlJIQZmL581yviaIxL_FWIDCmzI5r28EOQggyyQBBT", iamUrl: "https://gateway.watsonplatform.net/language-translator/api")
        
        language_translator.translate(text: ["Hello"], source: "en", target: "ru") { (translationResponse, translationError) in
            print(translationResponse)
        }
        */
    }
    
    
    
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }

    
    // Row Label is Represented as a Flag
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var rowLabel : String?
        switch row {
        case 0:
            rowLabel = "🇺🇸"
        case 1:
            rowLabel = "🇷🇺"
        case 2:
            rowLabel = "🇪🇸"
        default:
            rowLabel = nil
        }
        return rowLabel
    }
    
 }
