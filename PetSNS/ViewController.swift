//
//  ViewController.swift
//  PetSNS
//
//  Created by 今枝弘樹 on 2019/06/17.
//  Copyright © 2019 Hiroki Imaeda. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var userNameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userNameTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if UserDefaults.standard.object(forKey: "userName") != nil {
            performSegue(withIdentifier: "next", sender: nil)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        userNameTextField.resignFirstResponder()
    }
    
    @IBAction func login(_ sender: Any) {
        UserDefaults.standard.set(userNameTextField.text, forKey: "userName")
        performSegue(withIdentifier: "next", sender: nil)
        
    }
}

