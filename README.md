# Api with enum managment Demo

## Api Protocol
```
protocol ApiKey {
    var keys: [String] { get }
    var parametersForKeys: [Any?] { get }
    var httpMethod: HTTPMethod { get }
    var contentType: ContentType { get }
    var apiVersion: String { get }
}
```

## How to menagment
```
enum CustomApiKey: ApiKey {
	case customApi(parameter1: Any, parameter2: Any)
    
    init(_ apiKey: ApiKeySearch) {
        self = apiKey
    }
    
    var keys: [String] {
        switch self {
        case .customApi: return ["key1","key2"]
            
        }
    }
    
    var parametersForKeys: [Any?] {
        switch self {
        case .customApi(let parameter1, let parameter2): return [parameter1, parameter2]
        }
    }
    
    var httpMethod: HTTPMethod {
        switch self {
        case .customApi: return .get
        }
    }
    
    var contentType: ContentType {
        switch self {
        case .customApi: return .query
        }
    }
    
    var apiVersion: String { return "v1" }
}
```

## API URL
Url: Domain/v1/key1/parameter1/key2/parameter2



# How to use request

If using GET mehtod, parameter will be convert to query string

```
let apiKey = CustomApiKey(.customApi(parameter1: "1", parameter2: "2"))

var parameter: [String: Any] = [:]
parameter["para"] = "para"

Request.shared.api(from: apiKey, parameter: parameter).subscribe(onNext: { [weak self] (result) in
    guard let self = self else { return }
    switch result {
    case .success(let model): print(model)
    case .failure(let error): print(error)
    }
}).disposed(by: disposeBag)
```
