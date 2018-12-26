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
    let languages = ["Eng", "Rus"]
    
    var classificationResults : [String] = []
    var confidence: [Double] = []
    
    // Initialize constants - API Key, Watson URL
    let apiKey = "25ESV2meG8icq4NmUSO1K0uBtT0rmdbJ974zbBlm6NzE"
    let version = "2018-12-25"
    let watsonURL = "https://gateway.watsonplatform.net/visual-recognition/api"
    
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
                    
                    DispatchQueue.main.async {
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
    }
    
    
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    /*
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
    */
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
    
    /*
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var myImageView = UIImageView()
        
        switch row {
        case 0:
            myImageView = UIImageView(image: UIImage(named: "american_flag"))
        case 1:
            myImageView = UIImageView(image: UIImage(named: "russian_flag"))
        default:
            myImageView.image = nil
        }
        return myImageView
    }
    */
 }
