//
//  ViewController.swift
//  RxSwiftBasicUsage+API
//
//  Created by Adam Borek on 17/10/2016.
//  Copyright © 2016 Adam Borek. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire

class ViewController: UIViewController {
    let disposeBag = DisposeBag()
    let httpClient = HTTPClient()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zipSample()
    }
    
    func zipSample() {
        let dummyParameter = 1
        Observable.zip(httpClient.rx.firstResource(dummyParameter), httpClient.rx.secondResource()) { ($0, $1) }
            .subscribe(onNext: { response1, response2 in
                print("\n****************************")
                print(response1, response2, separator:"\n")
                print("****************************")
            }).addDisposableTo(disposeBag)
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
        }
    }
    
    func secondResource() -> Observable<String> {
        return Observable.create { observer in
            let reqeust = self.base.secondResource(callback: self.sendResponse(into: observer))
            return Disposables.create() {
                reqeust.cancel();
            }
        }
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
