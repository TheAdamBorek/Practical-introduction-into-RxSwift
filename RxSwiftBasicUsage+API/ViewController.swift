//
//  ViewController.swift
//  RxSwiftBasicUsage+API
//
//  Created by Adam Borek on 17/10/2016.
//  Copyright © 2016 Adam Borek. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire
import RxOptional
import RxSwiftExt

class ViewController: UIViewController {
    let disposeBag = DisposeBag()
    let httpClient = HTTPClient()
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldSample()
        buttonSample()
    }
    
    private func textFieldSample() {
        textField.rx.text
            .filterNil()                //textField.rx.text sends <String?> events. Here I ignore any nil to have only <String> events
            .distinctUntilChanged()     //When textField starts or ends beeing first responder it sends current text as <String> event. DistinctUntilChanged will propagete only those string which are diffrent than previous one.
            .debounce(0.3, scheduler: MainScheduler.instance)  //Here we wait 0.3 seconds to be sure that user doesn't want to tap multiple times
            .subscribe(onNext: { [weak self] text in
                self?.search(withQuery: text);
            }).addDisposableTo(disposeBag)
    }
    
    private func buttonSample() {
        button.rx.tap
            .debounce(0.3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.zipSample()
            }).addDisposableTo(disposeBag)
    }
    
    private func zipSample() {
        let dummyParameter = 1
        Observable.zip(httpClient.rx.firstResource(dummyParameter), httpClient.rx.secondResource()) { ($0, $1) }
            .subscribe(onNext: { response1, response2 in
                print("\n****************************\n[\(Date())]:\n")
                print(response1, response2, separator:"\n")
                print("****************************")
            }).addDisposableTo(disposeBag)
    }
    
    private func isFollowedByMe() -> Bool {
        return false
    }
    
    private func follow() {
        print("[\(Date())]: &&& I start to follow")
    }
    
    private func unfollow() {
        //unfollow
    }
    
    private func search(withQuery query: String) {
        print("[\(Date())]: ### Searching with query: \(query)")
    }
}

class HTTPClient {
    struct Error: Swift.Error {}
    let sessionManager: SessionManager = SessionManager()
    
    func firstResource(_ parameter: Int, callback: @escaping (Result<String>) -> Void) -> DataRequest {
        return sessionManager.request("http://adamborek.com/single-responsibility-principle-swift/")
            .validate(statusCode: 200..<300)
            .response{ response in
                let result = self.result(from: response)
                    .map { _ in
                        return "(1) Successfully downloaded resources from http://adamborek.com/single-responsibility-principle-swift/"
                }
                callback(result)
        }
    }
    
    func secondResource(callback: @escaping (Result<String>) -> Void) -> DataRequest {
        return sessionManager.request("http://adamborek.com/rules-for-better-swift-code/")
            .response { response in
                let result = self.result(from: response)
                    .map { _ in
                        return "(2) Successfully downloaded resources from http://adamborek.com/rules-for-better-swift-code/"
                }
                callback(result)
        }
    }
    
    func result(from response: DefaultDataResponse) -> Result<String> {
        let decoded = response.data.flatMap { data in
            return String(data:data, encoding: .utf8)
        }
        return result(from: decoded)
    }
    
    func result<T>(from decoded: T?) -> Result<T> {
        guard let decoded = decoded else {
            return Result.failure(HTTPClient.Error())
        }
        
        return Result.success(decoded);
    }
}

extension HTTPClient: ReactiveCompatible { }
extension Reactive where Base: HTTPClient {
    func firstResource(_ parameter: Int) -> Observable<String> {
        return Observable.create { observer in
            let reqeust = self.base.firstResource(parameter, callback: self.sendResponse(into: observer))
            return Disposables.create() {
                reqeust.cancel();
            }
        }.retry(.exponentialDelayed(maxCount: 3, initial: 2, multiplier: 1)) //Retry if receive an error. Maximum 3 attepts. First retry after 2 second, then after 4 seconds, then after 8 secnods
    }
    
    func secondResource() -> Observable<String> {
        return Observable.create { observer in
            let reqeust = self.base.secondResource(callback: self.sendResponse(into: observer))
            return Disposables.create() {
                reqeust.cancel();
            }
        }.retry(.exponentialDelayed(maxCount: 3, initial: 2, multiplier: 1))
    }
    
    func sendResponse<T>(into observer: AnyObserver<T>) -> ((Result<T>) -> Void) {
        return { result in
            switch result {
            case .success(let response):
                observer.onNext(response)
                observer.onCompleted()
            case .failure(let error):
                observer.onError(error)
            }
        }
    }
}

extension Result {
    typealias In = Value
    func map<Out>(transform: (In) -> Out) -> Result<Out> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }
}
