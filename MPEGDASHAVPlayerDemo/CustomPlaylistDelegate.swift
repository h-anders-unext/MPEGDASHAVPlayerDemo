//
//  CustomPlaylistDelegate.swift
//  MPEGDASHAVPlayerDemo
//
//  Created by Tomohiro Matsuzawa on 2019/11/28.
//  Copyright © 2019 Tomohiro Matsuzawa. All rights reserved.
//

import AVFoundation
import UIKit

let customPlaylistPrefix: Character = "u"
private let badRequestErrorCode = 400

func toCustomUrl(_ url: String) -> String {
    return String(customPlaylistPrefix) + url
}

func toOriginalUrl(_ url: String) -> String {
    guard url.first == customPlaylistPrefix else {
        return url
    }
    return String(url.dropFirst())
}

class CustomPlaylistDelegate: NSObject, AVAssetResourceLoaderDelegate {
    private func reportError(_ loadingRequest: AVAssetResourceLoadingRequest, withErrorCode error: Int) {
        loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: error, userInfo: nil))
    }

    /*!
     *  AVARLDelegateDemo's implementation of the protocol.
     *  Check the given request for valid schemes:
     */
    func resourceLoader(_: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let requestedURL = loadingRequest.request.url, let scheme = loadingRequest.request.url?.scheme else {
            return false
        }

        print("Requested: \(requestedURL.path)")

        if isCustomPlaylistSchemeValid(scheme) {
            DispatchQueue.main.async {
                self.handleCustomPlaylistRequest(loadingRequest)
            }
            return true
        }

        return false
    }
}



private extension CustomPlaylistDelegate {

    func isCustomPlaylistSchemeValid(_ scheme: String) -> Bool {
        return customPlaylistPrefix == scheme.first
    }

    func isMasterPlaylistURL(_ url: URL) -> Bool {
        return url.absoluteString == PlaylistInfo.masterPlaylistURL
    }

    func handleCustomPlaylistRequest(_ loadingRequest: AVAssetResourceLoadingRequest) {
        guard let customUrl = loadingRequest.request.url?.absoluteString else {
            reportError(loadingRequest, withErrorCode: badRequestErrorCode)
            return
        }

        guard let url = URL(string: toOriginalUrl(customUrl)) else {
            reportError(loadingRequest, withErrorCode: badRequestErrorCode)
            return
        }

        let request = URLRequest(url: url)

        DispatchQueue.main.async {
            if self.isMasterPlaylistURL(url) {
                loadingRequest.dataRequest?.respond(with: PlaylistInfo.masterPlaylist)
                loadingRequest.finishLoading()
            } else {
                loadingRequest.response = HTTPURLResponse(url: url, statusCode: 301, httpVersion: nil, headerFields: nil)
                loadingRequest.redirect = request
                loadingRequest.finishLoading()
            }
        }
        return
    }
}


struct PlaylistInfo {
    static let masterPlaylistURL = "master playlist url"
    static var masterPlaylist: Data {
        return """
PASTE M3U8 here
""".data(using: .utf8)!
    }
}
