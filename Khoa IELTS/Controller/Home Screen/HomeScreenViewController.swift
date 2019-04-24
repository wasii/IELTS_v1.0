//
//  HomeScreenViewController.swift
//  Khoa IELTS
//
//  Created by ColWorx on 02/01/2019.
//  Copyright © 2019 ast. All rights reserved.
//

import UIKit

class HomeScreenViewController: UIViewController {
    let menu = [
        [
            "title" : "Personal Matters & Hobbies",
            "image" : "q1"
        ],
        [
            "title" : "Technology",
            "image" : "q3"
        ],
        [
            "title" : "Environment, Animal & Nature",
            "image" : "q7"
        ],
        [
            "title" : "Travel & Holiday",
            "image" : "q2"
        ],
        [
            "title" : "Home, Hometown",
            "image" : "q4"
        ],
        [
            "title" : "Language, Study & Education",
            "image" : "q5"
        ],
        [
            "title" : "Health",
            "image" : "q6"
        ],
        [
            "title" : "Food",
            "image" : "q1"
        ],
        [
            "title" : "Media & Entertainment",
            "image" : "q7"
        ],
        [
            "title" : "Transport",
            "image" : "q3"
        ],
        [
            "title" : "History, Art & Culture",
            "image" : "q4"
        ],
        [
            "title" : "Society & Community",
            "image" : "q2"
        ]
    ]
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80
    }
    @IBAction func popBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension HomeScreenViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menu.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "HomeScreenCell", for: indexPath) as! HomeScreenTableViewCell

        
        
        let data = menu[indexPath.row]
        cell.initializeCell(data["title"]!, data["image"]!)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = menu[indexPath.row]
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let secondViewController = self.storyboard?.instantiateViewController(withIdentifier: "DetailHomeScreen") as! DetailHomeScreenViewController
        secondViewController.data = data
        
        self.navigationController!.pushViewController(secondViewController, animated: true)
    }
}

extension HomeScreenViewController :UITableViewDelegate {
    
}
