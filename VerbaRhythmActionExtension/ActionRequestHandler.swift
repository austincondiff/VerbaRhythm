//
//  ActionRequestHandler.swift
//  VerbaRhythmActionExtension
//
//  Created by Austin Condiff on 8/16/24.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    var extensionContext: NSExtensionContext?

    func beginRequest(with context: NSExtensionContext) {
        self.extensionContext = context
        print("Extension started")
        extractSharedText { [weak self] sharedText in
            guard let self = self else { return }

            if let content = sharedText,
               let encodedContent = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "verbarhythm://?sharedText=\(encodedContent)") {
                self.extensionContext?.open(url, completionHandler: { success in
                    if success {
                        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    } else {
                        // Handle the case where the URL could not be opened
                        self.doneWithResults()
                    }
                })
            } else {
                self.doneWithResults()
            }
        }
    }

    func extractSharedText(completion: @escaping (String?) -> Void) {
        if let item = self.extensionContext?.inputItems.first as? NSExtensionItem {
            for attachment in item.attachments ?? [] {
                if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                    attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { data, error in
                        if let text = data as? String {
                            completion(text)
                        } else {
                            completion(nil)
                        }
                    }
                    return
                }
            }
        }
        completion(nil)
    }

    func doneWithResults() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        self.extensionContext = nil
    }

}
