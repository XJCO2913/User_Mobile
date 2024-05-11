//
//  WebViewController.swift
//  UserLocation
//
//  Created by student on 3/5/2024.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet weak var myWebView: WKWebView!
    @IBOutlet weak var loader: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置 WebView 的代理
        myWebView.navigationDelegate = self
        
        // 加载网页
        if let url = URL(string: "http://43.136.232.116/") {
            let request = URLRequest(url: url)
            myWebView.load(request)
        }
    }
}

// 需要实现 WKNavigationDelegate 来处理网页加载事件
extension WebViewController: WKNavigationDelegate {
    // 网页开始加载时调用
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 显示加载指示器
        loader.startAnimating()
    }
    
    // 网页加载完成时调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 隐藏加载指示器
        loader.stopAnimating()
        loader.isHidden = true
        print("Web Page Loaded")
    }
    
    // 网页加载失败时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 隐藏加载指示器
        loader.stopAnimating()
        loader.isHidden = true
        print("Failed to load web page: \(error.localizedDescription)")
    }
}
