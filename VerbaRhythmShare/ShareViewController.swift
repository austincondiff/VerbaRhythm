//
//  ShareViewController.swift
//  VerbarhythmShare
//
//  Created by Austin Condiff on 8/13/24.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        if let content = extractSharedText() {
            let urlString = "verbarhythm://?sharedText=\(content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            if let url = URL(string: urlString) {
                self.extensionContext?.open(url, completionHandler: { (success) in
                    self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                })
            }
        } else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    func extractSharedText() -> String? {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in item.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                    var sharedText: String?
                    let semaphore = DispatchSemaphore(value: 0)
                    attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { (data, error) in
                        if let text = data as? String {
                            sharedText = text
                        }
                        semaphore.signal()
                    }
                    _ = semaphore.wait(timeout: .now() + 5)
                    return sharedText
                }
            }
        }
        return nil
    }
}
