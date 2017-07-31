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
        table.estimatedRowHeight = 50
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
        button.layer.masksToBounds = true
        button.layer.cornerRadius = CGFloat(Constants.AddButtonHeight / 2)
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    var listTask = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupView()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Your Saved Tasks"
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.red]
        loadData()
    }
    
    func loadData() {
        if let data = HFileManager.shared.readData(from: Constants.SavedFileName) {
            let str = String(data: data, encoding: String.Encoding.utf8)
            listTask = (str?.components(separatedBy: Constants.SeparateTaskComponent))!
        }
        
    }
    
    func setupView() {
        
        view.addSubview(tableView)
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
        
    }
    
    func showRecoderView() {
        recoderView.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.recoderView.alpha = 1
        })
    }
    
    func hideRecoderView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.recoderView.alpha = 0.1
        }) { _ in
            self.recoderView.isHidden = true
        }
    }
    
    func saveData() {
        var contents = ""
        for index in 0 ..< listTask.count - 1 {
            contents += listTask[index] + Constants.SeparateTaskComponent
        }
        contents += listTask[listTask.count - 1]
        _ = HFileManager.shared.writeData(input: contents, to: Constants.SavedFileName)
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
        return "Completed"
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
                maker.edges.equalTo(0).inset(5)
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
        }
    }
}

extension Constants {
    static let AddButtonHeight = 64
    static let SeparateTaskComponent = "Hyubyn"
    static let SavedFileName = "Hyubyn.info"
}
