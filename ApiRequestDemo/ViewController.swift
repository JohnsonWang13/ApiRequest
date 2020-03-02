//
//  ViewController.swift
//  ApiRequestDemo
//
//  Created by Johnson on 2020/3/2.
//  Copyright © 2020 presonal. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {
    
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchUsers()
    }

    private func searchUsers() {
        let apiKey = ApiKeySearch(.searchUser)
        
        var parameter: [String: Any] = [:]
        parameter["q"] = "searchText"
        parameter["per_page"] = 20
        parameter["page"] = 1
        
        Request.shared.api(from: apiKey, parameter: parameter).subscribe(onNext: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let model): print(model)
            case .failure(let error): print(error)
            }
        }).disposed(by: disposeBag)
    }

}

