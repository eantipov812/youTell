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
    let languages = ["en", "ru","fr"]
    var translations : [String] = []
    
    var classificationResults : [String] = []
    var confidence: [Double] = []
    
    // Initialize constants - API Key, Watson URL
    let apiKey = Constants.apiKey
    let version = Constants.version
    let watsonURL = Constants.watsonURL
    let translationURL = Constants.translationURL
    
    // Initialize Language Translator
    let language_translator = LanguageTranslator(version: "2018-12-27", apiKey: Constants.translationAPIKey)
    
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
            
            // Perform Visual Recognition
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
                    
                    // Get the most confident response
                    var highestConfidence = self.confidence.max()
                    let highestConfidenceIndex = self.confidence.index(of: highestConfidence!)
                    let bestClassification = self.classificationResults[highestConfidenceIndex!]
                    
                    // Limit Confidence Output To 2 Decimal Places
                    highestConfidence = Double(round(highestConfidence! * 100) / 100)
                    
                    
                    DispatchQueue.main.async {
                        // Add the recognized image and the confidence to the labels
                        self.wordLabel.text = bestClassification
                        self.confidenceLabel.text = String(highestConfidence! * 100) + "%"
                        
                }
                    self.translations.append(bestClassification)
                    self.getTranslations(word: bestClassification)
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
    }
    
    
    
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    // Function to Set the Number of Components in Each Row
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // Function To Set the Number of Rows
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    // Perform Assigned Task When Row Is Selected
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.wordLabel.text = translations[row]
    }
    
    // Get Translations Function To Get The Translations of the Word in Different Languages
    func getTranslations(word: String) {
        
        for index in 1..<languages.count {
            
            let target_lang = languages[index]
            
            language_translator.translate(text: [word], source: "en", target: target_lang, headers: [:]) { (translationResponse, translationError) in
                if translationError != nil {
                    print("There was an error with translation!")
                } else {
                    let translation = translationResponse?.result?.translations.first?.translationOutput
                    self.translations.append(translation!)
                    print(self.translations)
                }
            }
        }
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
            rowLabel = "🇫🇷"
        default:
            rowLabel = nil
        }
        return rowLabel
    }
    
 }
