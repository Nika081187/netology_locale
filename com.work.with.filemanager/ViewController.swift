//
//  ViewController.swift
//  com.work.with.filemanager
//
//  Created by v.milchakova on 20.04.2021.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    private let table = UITableView(frame: .zero, style: .grouped)
    let fm = FileManager.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        
        print(fm.urls(for: .documentDirectory, in: .userDomainMask))
        
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        
        view.addSubview(navBar)

        let navItem = UINavigationItem(title: "File Manager")
        let doneItem = UIBarButtonItem(title: "Create directory", style: .plain, target: nil, action: #selector(showAlert))
        let photoItem = UIBarButtonItem(title: "Take photo", style: .plain, target: nil, action: #selector(btnClicked))

        navItem.rightBarButtonItem = doneItem
        navItem.leftBarButtonItem = photoItem

        navBar.setItems([navItem], animated: false)
        
        table.toAutoLayout()
        table.allowsSelection = false

        table.register(UITableViewCell.self, forCellReuseIdentifier: "reuseId")
        table.dataSource = self
        
        self.navigationController?.navigationBar.isHidden = true
        table.backgroundColor = .white
        view.addSubview(table)
        
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    @objc func showAlert() {
        let ac = UIAlertController(title: "Enter directory name", message: nil, preferredStyle: .alert)
        ac.addTextField()

        let submitAction = UIAlertAction(title: "OK", style: .default) { [self, unowned ac] _ in
            let answer = ac.textFields![0]
            createDirectory(name: answer.text!)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    var imagePicker = UIImagePickerController()

    @objc func btnClicked() {

        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            print("Button capture")

            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false

            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func createDirectory(name: String) {
        if name.isEmpty { return }
        let documentsPath = NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        
        let logsPath = documentsPath.appendingPathComponent(name)
        print(logsPath!)
        do {
            try fm.createDirectory(atPath: logsPath!.path, withIntermediateDirectories: true, attributes: nil)
            
        } catch let error as NSError {
            print("Unable to create directory",error)
        }
        table.reloadData()
    }
    
    func saveImage(data: Data?) {
        let documentsDirectory = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let result = formatter.string(from: date)
        
        let fileName = "image-\(result).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        if let data = data, !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try data.write(to: fileURL)
                print("file saved")
            } catch {
                print("error saving file:", error)
            }
        }
        table.reloadData()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        let result = image?.jpegData(compressionQuality:  1.0)
        saveImage(data: result)
        picker.dismiss(animated: true, completion: nil)
    }
}

extension UIView {
    func toAutoLayout() {
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowsCount = getFiles().count
        return rowsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseId", for: indexPath)
        let row = getFiles()[indexPath.row].path
        cell.textLabel?.text = (row as NSString).lastPathComponent
        return cell
    }
    
    func getFiles() -> [URL] {
        var urls: [URL]
        urls = fm.urls(for: .documentDirectory, in: .userDomainMask)
        do {
            urls = try fm.contentsOfDirectory(at: urls[0], includingPropertiesForKeys: nil)
            print("fileURLsCount: \(urls)")
        } catch {
            print("Error while enumerating files: \(error.localizedDescription)")
        }
        return urls
    }
}
