//
//  UIImageView+ImageLoader.swift
//  ImageLoader
//
//  Created by Hirohisa Kawasaki on 10/17/14.
//  Copyright (c) 2014 Hirohisa Kawasaki. All rights reserved.
//

import Foundation
import UIKit

private var ImageLoaderURLKey = 0
private var ImageLoaderBlockKey = 0

/**
    Extension using ImageLoader sends a request, receives image and displays.
*/
extension UIImageView {

    // MARK: - properties

    private var URL: NSURL? {
        get {
            return objc_getAssociatedObject(self, &ImageLoaderURLKey) as? NSURL
        }
        set(newValue) {
            objc_setAssociatedObject(self, &ImageLoaderURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private var block: AnyObject? {
        get {
            return objc_getAssociatedObject(self, &ImageLoaderBlockKey)
        }
        set(newValue) {
            objc_setAssociatedObject(self, &ImageLoaderBlockKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - public
    public func load(URL: URLLiteralConvertible, placeholder: UIImage? = nil, completionHandler:CompletionHandler? = nil) {
        cancelLoading()

        if let placeholder = placeholder {
            image = placeholder
        }

        self.URL = URL.imageLoaderURL
        _load(URL.imageLoaderURL, completionHandler: completionHandler)
    }

    public func cancelLoading() {
        if let URL = URL {
            Manager.sharedInstance.cancel(URL, block: block as? Block)
        }
    }

    // MARK: - private
    private static let _requesting_queue = dispatch_queue_create("swift.imageloader.queues.requesting", DISPATCH_QUEUE_SERIAL)

    private func _load(URL: NSURL, completionHandler: CompletionHandler?) {

        let completionHandler: (NSURL, UIImage?, NSError?, CacheType) -> Void = { URL, image, error, cacheType in

            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                // requesting is success then set image
                if let thisURL = self?.URL, let image = image where thisURL.isEqual(URL) {
                    self?.image = image
                }
                completionHandler?(URL, image, error, cacheType)
            })
        }

        // caching
        if let image = Manager.sharedInstance.cache[URL] {
            completionHandler(URL, image, nil, .Cache)
            return
        }

        dispatch_async(UIImageView._requesting_queue, {
            let loader = Manager.sharedInstance.load(URL).completionHandler(completionHandler)
            self.block = loader.blocks.last
        })

    }

}