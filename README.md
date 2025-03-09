
# HTTPable - Swift Package

Simplifying HTTP requests in Swift with Gettable & Postable.

## Configure

Add these lines in the main App struct of your Swift project.

```swift
let configs = HTTPConfig(baseURL: "https://example.com")
HTTPable.configure(configs)
```
#### Example:
```swift
@main
struct myApp: App {

    let configs = HTTPConfig(baseURL: "https://example.com")
    HTTPable.configure(configs)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```
## Usage
### GET - `Gettable`

#### Creating instance:
```swift
let gettable = Gettable<AnyCodableResponseBody>([
    APIPath.to("foo"),
    APIPath.to("bar"),
    APIPath.param(key: "id")
])
```
> https://example.com/foo/bar/{:id}


#### Preparing request:
```swift
var request = gettable.request
```
#### Defining params:
```swift
request.params.append(Param(key: "id", "001"))
```
> https://example.com/foo/bar/001

#### Adding queries:
```swift
request.query.append(Query(key: "date", "2024-11-21"))
request.query.append(Query(key: "active", "true"))
```
> https://example.com/foo/bar/001?date=2024-11-21&active=true

#### Getting:
```swift
gettable.get(with: request) { response in 
    if let error = response.error { /** handle error */ }
    if let body = response.body { /** handle body */ }
}
```

### POST - `Postable`
```swift
let postable = Postable<RequestBody,ResponseBody>([APIPath.to("foo")])

var request = postable.request
```
`params` and `query` can be applied.
#### Request body:
```swift
request.body = RequestBody(bar: "baz")
```
#### Posting:
```swift
postable.post(with: request) { response in
    if let error = response.error { /** handle error */ }
    if let body = response.body { /** handle body */ }
}
```
