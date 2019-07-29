//
//  ShareViewController.swift
//  PetSNS
//
//  Created by 今枝弘樹 on 2019/06/18.
//  Copyright © 2019 Hiroki Imaeda. All rights reserved.
//

import UIKit
import Photos
import VisualRecognitionV3
import Firebase
import EMAlertController
import SVProgressHUD

class ShareViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var cameraImageView: UIImageView!
    
    var fullNameArray = [String]()
    var postImageArray = [String]()
    var commentArray = [String]()
    
    var fullName = String()
    var postImageURL: URL!
    var postImage = UIImage()
    
    //VisualRecognitionを使う時のAPIkey
    let apiKey = "Ofi73saibQ1Yzb-8-m6Ls_y1iT6PKT6EyndJVT2R1jC9"
    let version = "2019-06-19"
    
    var dogOrNot: Bool = true
    var resultString = String()
    var clasificationResult: [String] = []
    
    var userName = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        
        PHPhotoLibrary.requestAuthorization { (status) in
            switch(status){
            case .authorized:
                break
            case .denied:
                break
            case .notDetermined:
                break
            case .restricted:
                break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.userName = UserDefaults.standard.object(forKey: "userName") as! String
    }
    
    @IBAction func camera(_ sender: Any) {
        let camera = UIImagePickerController.SourceType.camera
        if UIImagePickerController.isSourceTypeAvailable(camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.sourceType = camera
            cameraPicker.delegate = self
            cameraPicker.allowsEditing = true
            self.present(cameraPicker, animated: true, completion: nil)
        } else {
            print("camera error")
        }
    }
    
    @IBAction func album(_ sender: Any) {
        let photoLibrary = UIImagePickerController.SourceType.photoLibrary
        if UIImagePickerController.isSourceTypeAvailable(photoLibrary) {
            let libraryPicker = UIImagePickerController()
            libraryPicker.sourceType = photoLibrary
            libraryPicker.delegate = self
            libraryPicker.allowsEditing = true
            self.present(libraryPicker, animated: true, completion: nil)
        } else {
            print("album error")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        SVProgressHUD.show()
        if let pickedImage = info[.originalImage] as? UIImage {
            self.cameraImageView.image = pickedImage
            let visualR = VisualRecognition(version: version, apiKey: apiKey, iamUrl: nil)
            let imageData = pickedImage.jpegData(compressionQuality: 1.0)
            let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let fileURL = documentURL?.appendingPathComponent("tempImage.jpg")
            try! imageData?.write(to: fileURL!, options: [])
            self.clasificationResult = []
            visualR.classify(imagesFile: imageData, imagesFilename: nil, imagesFileContentType: "jpeg", url: nil, threshold: nil, owners: nil, classifierIDs: ["default"], acceptLanguage: "ja", headers: nil) { (response, error) in
                if let classfiedImages = response?.result {
                    print(classfiedImages)
                    let classes = classfiedImages.images.first!.classifiers.first!.classes
                    for index in 0..<classes.count {
                        self.clasificationResult.append(classes[index].className)
                        if self.clasificationResult.contains("犬"){
                            DispatchQueue.main.async {
                                print("犬です")
                                self.dogOrNot = true
                                SVProgressHUD.dismiss()
                            }
                        } else {
                            DispatchQueue.main.async {
                                print("犬じゃないです")
                                self.dogOrNot = false
                                SVProgressHUD.dismiss()
                            }
                        }
                    }
                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func postData() {
        let rootRef = Database.database().reference(fromURL: "https://petsns-ba9dc.firebaseio.com/").child("post")
        let storage = Storage.storage().reference(forURL: "gs://petsns-ba9dc.appspot.com/")
        guard let key = rootRef.child("User").childByAutoId().key else {
            print("keyが取得できませんでした")
            return
        }
        let imageRef = storage.child("Users").child("\(key).jpg")
        var data: NSData = NSData()
        if let image = cameraImageView.image {
            data = image.jpegData(compressionQuality: 1.0)! as NSData
        }
        let uploadTask = imageRef.putData(data as Data, metadata: nil) { (metadata, error) in
            if error != nil {
                SVProgressHUD.show()
                return
            }
            imageRef.downloadURL(completion: { (url, error) in
                if url != nil {
                    let feed = ["postImage": url?.absoluteString as Any, "comment": self.textView.text!, "fullName": self.userName] as [String: Any]
                    let postFeed = ["\(key)": feed]
                    rootRef.updateChildValues(postFeed)
                    SVProgressHUD.dismiss()
                }
            })
        }
        uploadTask.resume()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func share(_ sender: Any) {
        if dogOrNot == true {
            let alert = EMAlertController(icon: UIImage(named: "dogIcon.jpg"), title: "やったね！", message: "この写真は犬だよ")
            let action = EMAlertAction(title: "OK", style: .cancel)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.postData()
            }
        } else {
            let alert = EMAlertController(icon: UIImage(named: "dogIcon.jpg"), title: "ごめんなさい！", message: "この写真には犬は写ってないよ")
            let action = EMAlertAction(title: "OK", style: .cancel)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func back(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }
}
