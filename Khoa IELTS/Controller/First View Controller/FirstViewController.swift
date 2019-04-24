//
//  FirstViewController.swift
//  Khoa IELTS
//
//  Created by Office on 4/23/19.
//  Copyright © 2019 ast. All rights reserved.
//

import UIKit

class FirstViewController: UIViewController {

    @IBOutlet weak var testNow: RoundedButtons!
    @IBOutlet weak var practice: RoundedButtons!
    @IBOutlet weak var testNowWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var practiceWidthConstraint: NSLayoutConstraint!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
        setup()
    }
    func setup() {
        UIView.animate(withDuration: 0.2, animations: {
            self.testNowWidthConstraint.constant = 300
            self.view.layoutIfNeeded()
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.practiceWidthConstraint.constant = 300
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
        
    }
    
    @IBAction func practiceBtnTapped(_ sender: Any) {
        let mainTabBar = self.storyboard?.instantiateViewController(withIdentifier: "MainTabBar") as! MainTabBarViewController
        
        self.navigationController?.pushViewController(mainTabBar, animated: true)
    }
    @IBAction func testNowBtnTapped(_ sender: Any) {
        let recordingScreen = self.storyboard?.instantiateViewController(withIdentifier: "RecordingScreen") as! RecordingScreenViewController
//        recordingScreen.data =
        recordingScreen.data = ["title" : "Individual Wealth" as AnyObject,
                          "part" : "Part - 1" as AnyObject,
                          "topics" : [
                            "Are there many wealthy people in your country?",
                            "How did they become so wealthy?",
                            "If you were wealthy, how would your life change?",
                            "Can wealth sometimes lead to unhapiness? How?"
                            ] as AnyObject,
                          "topicTitle" : "Individual Wealth"
            ] as [String:AnyObject]
        self.navigationController?.pushViewController(recordingScreen, animated: true)
    }
}
