//
//  HFileManager.swift
//  SpeechToText
//
//  Created by NguyenVuHuy on 7/31/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

import UIKit

class HFileManager {
    static let shared = HFileManager()
    
    let fileManager = FileManager.default
    
    /*
     function getFilePath
     params: fileName
     return: file path by append filename to currentDirectoryPath
     */
    
    func getFilePath(fileName: String) -> String {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let path = documents.appending("/\(fileName)")
        print(path)
        return path
    }
    
    /*
     function: checkFileExist
     params: the name of file
     return: true if file exist, else return false
     */
    func checkFileExist(fileName: String) -> Bool {
        
        if fileManager.fileExists(atPath: getFilePath(fileName: fileName)) {
            return true
        } else {
            return false
        }
    }
    
    /*
     function: read Data from file
     params: fileName type String
     return: Data from file if can read file or nil if cannot read file
     */
    
    func readData(from fileName: String) -> Data? {
        let file: FileHandle? = FileHandle(forReadingAtPath: getFilePath(fileName: fileName))
        
        if file != nil {
            // Read all the data
            let data = file?.readDataToEndOfFile()
            
            // Close the file
            file?.closeFile()
            
            // Convert our data to string
            let str = String(data: data!, encoding: String.Encoding.utf8)
            print(str!)
            
            print("Read data successed")
            
            return data
        }
        else {
            print("Ooops! Something went wrong!")
            return nil
        }
        
    }
    
    /*
     function: read string from file
     params: fileName type String
     return: string from file if can read file or nil if cannot read file
     */
    
    func readString(from fileName: String) -> String? {
        // Set the file path
        let path = getFilePath(fileName: fileName)
        
        do {
            // Get the contents
            let contents = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            print(contents)
            return contents
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            return nil
        }
    }
    
    /*
     function: write data to file
     params: input string to write to file, fileName type String
     return: true if write successed, false if write failed
     */
    func writeData(input: String, to fileName: String) -> Bool {
        // Create a FileHandle instance
        let path = getFilePath(fileName: fileName)
        if !checkFileExist(fileName: fileName) {
            print("File does not exist create new file")
            fileManager.createFile(atPath: fileName, contents: input.data(using: String.Encoding.utf8), attributes: nil)
            return true
        }
        let file: FileHandle? = FileHandle(forWritingAtPath: path)
        
        if file != nil {
            // Set the data we want to write
            let data = input.data(using: String.Encoding.utf8)
            
            // Write it to the file
            file?.write(data!)
            
            // Close the file
            file?.closeFile()
            
            print("Write to file successed")
            return true
        }
        else {
            print("Ooops! Something went wrong!")
            return false
        }
    }
    
    /*
     function: write string to file
     params: input string to write to file, fileName type String
     return: true if write successed, false if write failed
     */
    func writeString(contents: String,to fileName: String) -> Bool {
        if !checkFileExist(fileName: getFilePath(fileName: fileName)) {
            print("File does not exist create new file")
            fileManager.createFile(atPath: getFilePath(fileName: fileName), contents: contents.data(using: String.Encoding.utf8), attributes: nil)
            return true
        }
        do {
            // Write contents to file
            try contents.write(toFile: getFilePath(fileName: fileName), atomically: false, encoding: String.Encoding.utf8)
            print("Write to file successed")
            return true
        }
        catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            return false
        }
    }
}
