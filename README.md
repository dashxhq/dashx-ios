# dashx-ios

_DashX iOS SDK_

## Installation

- Go to *File* > *Swift Packages* > *Add Package Dependency*
- Paste the URL to this repo (https://github.com/dashxhq/dashx-ios.git) into the search bar, then hit the Next button.
- Under *Rules* select `Up To Next Minor`, you can put version `0.0.1`
- Select `DashX` package

## Usage

```swift
var dashXClient = DashXClient(withPublicKey: "Your Public Key")
```

DashXClient can be initialised with:

|Name|Type|
|:---:|:--:|
|**`withPublicKey`**|`String` _(Required)_ |
|**`withAccountType`**|`String`|
|**`withBaseUri`**|`String`|
|**`withTargetInstallation`**|`String`|
|**`withTargetEnvironment`**|`String`|

### Identify User

```swift
dashXClient.identify(uid, withOptions: options)
```

`withOptions` is a `NSDictionary` of

|Name|Type|
|:---:|:--:|
|**`firstName`**|`String`|
|**`lastName`**|`String`|
|**`name`**|`String`|
|**`email`**|`String`|
|**`phone`**|`String`|

### Track Events

```swift
dashXClient.track(event, withData: data)
```

`withData` accepts [String:String]

### Fetch Content

```swift
dashXClient.fetchContent("content_type/content", language: "en_US", {
    result in log(result)
}, {
    error in log(error)
})
```

`fetchContent` accepts following arguments

|Name|Type|Example|
|:--:|:--:|:-----:|
|**`preview`**|`boolean`||
|**`language`**|`String`|`"en_US"`||
|**`fields`**|`[String]`|`["character", "cast"]`||
|**`include`**|`[String]`|`["character.createdBy", "character.birthDate"]`||
|**`exclude`**|`[String]`|`["directors"]`||

### Search Content

```swift
dx.searchContent("contacts",
    returnType: "all",
    filter: ["name_eq": "John"],
    order: ["created_at": "DESC"],
    preview: true,
    limit: 10,
    {
        result in log(result)
    },
    {
        error in log(error)
    }
)
```

`searchContent` accepts following arguments

|Name|Type|Example|
|:--:|:--:|:-----:|
|**`returnType`**|`"all"` or `"one"`||
|**`filter`**|`[String: String]`|`["name_eq": "John"]`|
|**`order`**|`[String: String]`|`["created_at": "DESC"]`|
|**`limit`**|`Int`||
|**`preview`**|`Bool`||
|**`language`**|`String`|`"en_US"`||
|**`fields`**|`[String]`|`["character", "cast"]`||
|**`include`**|`[String]`|`["character.createdBy", "character.birthDate"]`||
|**`exclude`**|`[String]`|`["directors"]`||
