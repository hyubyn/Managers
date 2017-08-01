//
//  ViewController.swift
//  SpeechToText
//
//  Created by NguyenVuHuy on 7/27/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

import UIKit
import SnapKit
import Speech

class ViewController: UIViewController {
  
    lazy var tableView: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.tableFooterView = UIView()
        table.separatorStyle = .singleLine
        table.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
        table.allowsMultipleSelectionDuringEditing = false
        table.rowHeight = UITableViewAutomaticDimension         // this two lines make the height of uitableviewcell change dynamically
        table.estimatedRowHeight = 80
        return table
    }()
    
    lazy var recoderView: RecorderView = {
        let view = RecorderView()
        view.delegate = self
        view.isHidden = true
        return view
    }()
    
    lazy var addButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "add_icon"), for: .normal)
        button.addTarget(self, action: #selector(showRecoderView), for: .touchUpInside)
        button.backgroundColor = UIColor.red
        button.layer.masksToBounds = false
        button.layer.cornerRadius = CGFloat(Constants.AddButtonHeight / 2)
        button.backgroundColor = UIColor.clear
        button.layer.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
        button.layer.shadowOffset = CGSize.init(width: 0, height: 2.0)
        return button
    }()
    
    lazy var leftBarButton: UIButton = {
        let button = UIButton(frame: CGRect.init(x: 0, y: 0, width: 30, height: 30))
        button.addTarget(self, action: #selector(changeLocale), for: .touchUpInside)
        return button
    }()
    
    lazy var rightBarButton: UIButton = {
        let button = UIButton(frame: CGRect.init(x: 0, y: 0, width: 30, height: 30))
        button.addTarget(self, action: #selector(clearAllTask), for: .touchUpInside)
        button.setImage(#imageLiteral(resourceName: "completed"), for: .normal)
        return button
    }()
    
    lazy var noTaskLable: UILabel = {
        let label = UILabel()
        label.text = "No recent tasks"
        label.textAlignment = .center
        label.textColor = UIColor.brown.withAlphaComponent(0.5)
        label.font = UIFont.systemFont(ofSize: 30)
        label.numberOfLines = 2
        return label
    }()
    
    var listTask = [String]()
    var isUsingEnglish = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupView()
        
        addObserver(listTask as! NSMutableArray, forKeyPath: #keyPath(listTask), options: [.new, .old], context: nil)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print(keyPath ?? "count change")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = Constants.MainTitle
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        loadData()
        isUsingEnglish = UserDefaults.standard.bool(forKey: Constants.SavedLocaledKey)
        changeLocale()
    }
    
    //clear all recent tasks
    func clearAllTask() {
        let alert = UIAlertController(title: "Clear All Task", message: "Did you complete all task? Press Clear to clear all recent tasks.\nIf not, swipe left each task to mark it as completed", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Clear", style: .default) { (_) in
            if self.listTask.count == 0 { return }
            self.listTask.removeAll()
            self.tableView.reloadData()
            self.saveData()
            self.checkNumberOfTask()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    // change locale
    func changeLocale() {
        // using Eng - change to VN
        if !isUsingEnglish {
            recoderView.setLocale(isUS: false)
            leftBarButton.setImage(#imageLiteral(resourceName: "vn"), for: .normal)
            UserDefaults.standard.set(isUsingEnglish, forKey: Constants.SavedLocaledKey)
        } else {
            recoderView.setLocale(isUS: true)
            leftBarButton.setImage(#imageLiteral(resourceName: "us"), for: .normal)
            UserDefaults.standard.set(isUsingEnglish, forKey: Constants.SavedLocaledKey)
        }
        isUsingEnglish = !isUsingEnglish
    }
    
    // load saved task from local
    func loadData() {
        if let data = HFileManager.shared.readData(from: Constants.SavedFileName) {
            if let str = String(data: data, encoding: String.Encoding.utf8) {
                listTask = (str.components(separatedBy: Constants.SeparateTaskComponent)).filter{$0 != ""}
                checkNumberOfTask()
            }
        }
        
    }
    
    // check number of task to show no task label 
    func checkNumberOfTask() {
        if listTask.count == 0 {
            noTaskLable.isHidden = false
            navigationItem.title = Constants.MainTitle2
        } else {
            navigationItem.title = Constants.MainTitle
            noTaskLable.isHidden = true
        }
    }
    
    // setup view components
    func setupView() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftBarButton)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightBarButton)
        navigationController?.navigationBar.barTintColor = Constants.ThemeColor
        
        view.addSubview(tableView)
        view.addSubview(noTaskLable)
        view.addSubview(addButton)
        view.addSubview(recoderView)
        
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(0).inset(5)
        }
        
        addButton.snp.makeConstraints { (maker) in
            maker.trailing.bottom.equalTo(0).inset(20)
            maker.width.height.equalTo(Constants.AddButtonHeight)
        }
        
        recoderView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(0)
        }
     
        noTaskLable.snp.makeConstraints { (maker) in
            maker.edges.equalTo(tableView)
        }
    }
    
    func showRecoderView() {
        recoderView.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.recoderView.alpha = 1
            self.recoderView.textView.text = ""
        })
    }
    
    func hideRecoderView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.recoderView.alpha = 0.1
        }) { _ in
            self.recoderView.isHidden = true
        }
    }
    
    // save data to file, in case clear all tasks - contents will be an empty string
    func saveData() {
        var contents = ""
        
        if listTask.count > 1 {
            for index in 0 ..< listTask.count - 1 {
                contents += listTask[index] + Constants.SeparateTaskComponent
            }
            contents += listTask[listTask.count - 1]
            _ = HFileManager.shared.writeData(input: contents, to: Constants.SavedFileName)
        } else {
            _ = HFileManager.shared.writeString(contents: contents, to: Constants.SavedFileName)
        }
        
        
    }
}

extension ViewController: RecorderViewDelegate {
    func didCancelRecord() {
        hideRecoderView()
    }
    
    func didRecordTask(task: String) {
        listTask.append(task)
        tableView.reloadData()
        hideRecoderView()
        saveData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listTask.count
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return Constants.CompletedLabelName
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as UITableViewCell
        if let label = cell.viewWithTag(1024) as? UILabel {
            label.text = listTask[indexPath.row]
        } else {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 18)
            label.text = listTask[indexPath.row]
            label.tag = 1024
            label.numberOfLines = 0
            label.textColor = UIColor.blue
            label.textAlignment = .center
            cell.addSubview(label)
            label.snp.makeConstraints({ (maker) in
                maker.edges.equalTo(0).inset(10)
            })
        }
        cell.preservesSuperviewLayoutMargins = false // this three lines make the separate line between row to be drawn from beggining to the end
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            listTask.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            saveData()
            checkNumberOfTask()
        }
    }
}

extension Constants {
    static let AddButtonHeight = 64
    static let SeparateTaskComponent = "Hyubyn"
    static let SavedFileName = "Hyubyn.info"
    static let CompletedLabelName = "Completed"
    static let MainTitle = "Your Saved Tasks"
    static let MainTitle2 = "Add New Task"
    static let SavedLocaledKey = "SavedLocaleKey"
}
