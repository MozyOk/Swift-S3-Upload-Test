//
//  ViewController.swift
//  Swift S3 Upload Test
//
//  Created by Mozy on 2018/11/18.
//  Copyright © 2018年 Mozy. All rights reserved.
//

import UIKit
import SSZipArchive
import AWSS3

class ViewController: UIViewController {
    
    @IBOutlet weak var uploadButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onTappedUploadButton (_ sender: UIButton) {
        // Documentsディレクトリ絶対パス
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        // アーカイブファイル名
        let archiveFile = "archive.zip"
        // アーカイブファイル絶対パス
        let archivePath = documentDir.appendingPathComponent(archiveFile)
        // アーカイブファイルパスワード
        let archivePassword = "hogehoge"
        
        // 送信ボタンの処理
        let defaultAction = UIAlertAction(title: "アップロード", style: .default, handler: {
            [archiveData, uploadData, showAlert] (action: UIAlertAction!) -> Void in
            sender.isEnabled = false
            // アーカイブ処理
            if archiveData(archivePath, archivePassword) {
                // アップロード処理
                uploadData(archivePath, archiveFile, {
                    sender.isEnabled = true
                    showAlert("アップロード", "S3へのアップロードが完了しました。")
                }, { error in
                    if let e = error as NSError? {
                        print("localizedDescription:\n\(e.localizedDescription)")
                        print("userInfo:\n\(e.userInfo)")
                    }
                    sender.isEnabled = true
                    showAlert("アップロード", "S3へのアップロードが失敗しました。")
                })
            } else {
                sender.isEnabled = true
                showAlert("アーカイブ", "アーカイブが失敗しました。")
            }
        })
        
        // キャンセルボタンの処理
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        
        // 送信確認
        let confirmation = UIAlertController(title: "確認", message: "S3へアップロードしてもいいですか？", preferredStyle: .alert)
        confirmation.addAction(defaultAction)
        confirmation.addAction(cancelAction)
        self.present(confirmation, animated: true, completion: nil)
    }
    
    // アラート表示
    func showAlert(title: String, message: String) {
        // OKボタンの処理
        let defaultAction = UIAlertAction(title: "OK", style: .default)
        
        // アラート表示
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(defaultAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Documentsディレクトリ内のresourceディレクトリをアーカイブ
    func archiveData(archivePath: String, password: String) -> Bool {
        // Documentsディレクトリ絶対パス
        let documentDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        // 圧縮元ファルパス = resource
        let resourcePath = documentDir.appendingPathComponent("resource")
        // パスワード付きデータ圧縮
        return SSZipArchive.createZipFile(atPath: archivePath, withContentsOfDirectory: resourcePath, withPassword: password)
    }
    
    // archive.zipをS3へアップロード
    func uploadData(archivePath: String, archiveFile: String, complete: @escaping () -> Void, failure: @escaping (Error?) -> Void) {
        // Documentsディレクトリの絶対パス
        let transferUtility = AWSS3TransferUtility.default()
        let url = URL(fileURLWithPath: archivePath)
        let bucket = "バケット名"
        let contentType = "application/zip"
        
        // アップロード中の処理
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = {(task, progress) in
            DispatchQueue.main.async {
                // Do something e.g. Update a progress bar.
            }
        }
        
        // アップロード後の処理
        let completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async {
                // Do something e.g. Alert a user for transfer completion.
                // On failed uploads, `error` contains the error object.
                if let error = error {
                    failure(error) // 失敗
                } else {
                    complete() // 成功
                }
            }
        }
        
        // アップロード
        transferUtility.uploadFile(
            url,
            bucket: bucket,
            key: archiveFile,
            contentType: contentType,
            expression: expression,
            completionHandler: completionHandler
            ).continueWith { (task) -> Any? in
                if let error = task.error as NSError? {
                    print("localizedDescription:\n\(error.localizedDescription)")
                    print("userInfo:\n\(error.userInfo)")
                }
                if let _ = task.result {
                    // Do something with uploadTask.
                }
                return nil
        }
    }

}

