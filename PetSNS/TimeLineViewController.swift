//
//  TimeLineViewController.swift
//  PetSNS
//
//  Created by 今枝弘樹 on 2019/06/18.
//  Copyright © 2019 Hiroki Imaeda. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import SVProgressHUD

class TimeLineViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    let refleshControl = UIRefreshControl()
    
    var fullNameArray = [String]()
    var postImageArray = [String]()
    var commentArray = [String]()
    
    var posts = [Post]()
    var posst = Post()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        refleshControl.attributedTitle = NSAttributedString(string: "更新します")
        refleshControl.addTarget(self, action: #selector(reflesh), for: .valueChanged)
        tableView.addSubview(refleshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPost()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SVProgressHUD.dismiss()
    }
    
    @objc func reflesh() {
        fetchPost()
        refleshControl.endRefreshing()
    }
    
    func fetchPost() {
        self.posts = [Post]()
        self.fullNameArray = [String]()
        self.postImageArray = [String]()
        self.commentArray = [String]()
        self.posst = Post()
        
        let ref = Database.database().reference()
        ref.child("post").queryLimited(toLast: 10).observeSingleEvent(of: .value) { (snap, error) in
            let postsSnap = snap.value as? [String: NSDictionary]
            if postsSnap == nil {
                return
            }
            self.posts = [Post]()
            for (_,post) in postsSnap! {
                self.fullNameArray = [String]()
                self.postImageArray = [String]()
                self.commentArray = [String]()
                self.posst = Post()
                
                if let comment = post["comment"] as? String, let userName = post["fullName"] as? String, let postImage = post["postImage"] as? String {
                    self.posst.comment = comment
                    self.posst.fullName = userName
                    self.posst.postImage = postImage
                    
                    self.commentArray.append(self.posst.comment)
                    self.fullNameArray.append(self.posst.fullName)
                    self.postImageArray.append(self.posst.postImage)
                    
                }
                self.posts.append(self.posst)
            }
            self.tableView.reloadData()
            /*self.posts = [Post]()
            for case let child as DataSnapshot in snap.children {
                guard let post = child.value as? [String: Any] else {
                    continue
                }
                let posst = Post()
                if let comment = post["comment"] as? String, let userName = post["userName"] as? String, let postImage = post["postImage"] as? String {
                    self.posst.comment = comment
                    self.posst.fullName = userName
                    self.posst.postImage = postImage
                    
                    self.commentArray.append(self.posst.comment)
                    self.fullNameArray.append(self.posst.fullName)
                    self.postImageArray.append(self.posst.postImage)
                }
                self.posts.append(posst)
            }
            self.posts = self.posts.reversed()
            self.tableView.reloadData()*/
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let profileImageView = cell.viewWithTag(1) as! UIImageView
        let profileImageURL = URL(string: self.posts[indexPath.row].postImage as String)!
        profileImageView.sd_setImage(with: profileImageURL, completed: nil)
        profileImageView.layer.cornerRadius = 8.0
        profileImageView.clipsToBounds = true
        
        let userNameLabel = cell.viewWithTag(2) as! UILabel
        userNameLabel.text = self.posts[indexPath.row].fullName
        
        let commentLabel = cell.viewWithTag(3) as! UILabel
        commentLabel.text = self.posts[indexPath.row].comment
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 400
    }
    
}
