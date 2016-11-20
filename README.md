**Property List** is a convenient and flexible format for saving data. It was originally defined by apple, to use in iOS devices and later extended to various apps. Plist internally is actually an XML file and can easily be converted to JSON file format as well.
Xcode provides a nice visual tool to edit and view contents of a `.plist` file.

<a href="/assets/img/infoPlist.png"><img src="/assets/img/infoPlist.png" class="img-responsive center-block img-thumbnail" width="270" height="480" /></a>
<figcaption>Typical Info.plist file</figcaption>

In the context of iOS, a plist file is used in many places. To store the basic information of an app, every target has a `info.plist` file which contains information like `bundle Id`, `product name`, `version no`, `background modes`, etc. If your app has a settings bundle, you save the information in `Root.plist` inside the bundle. So we can see Plist is a very popular format when it comes to iOS app development.

The best thing about it is, we can use `Plist` for storing other custom information. It's often a good practice to store various hard-coded key-value pairs in plist, for instance: API path name, screen toggle mode, app configuration, private tokens, etc. One thing, is if your plist file contains sensitive and private information, you should encrypt the file before shipping it out.

It's easy to edit and save information in a plist file, but let's talk about reading it from iOS app, because that's what we are more focused on. The ease of using plist file. Generally, we don't write to a plist file using `code`, but we must `read` from code.

Let's see the logic of reading a plist file:
#### Easy but not so safe approach
A plist can be converted into a Dictionary. If you know the key of a dictionary, you can get the value of it.
```swift
if let path = Bundle.main.path(forResource: "Debug", ofType: "plist"),
  let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
    ... // We have a dictionary now
}
```

Doesn't it seem very easy? Yes, it does. But, why is it unsafe? Let's imagine you have a plist whose JSON equivalent looks like this
```
{
  key1: {
    key11: {
      key111: {
        keyFinal: "result"
      }
    }
  }
}
```

You'd need to know before hand, where your final value is. In this case `key1 -> key11 -> key111 -> keyFinal`. You need to check for validity and type guarantee at every key. Let's attempt to write, how we could read the final value `result`
```swift
// Assuming we already have dict from previous step
if let dict1 = dict["key1"] as? [String: Any],
  let dict2 = dict1["key11"] as? [String: Any],
  let dict3 = dict2["key111"] as? [String; Any],
  let finalValue = dict3["keyFinal"] as? String {
    ... // We have the final value "value" here now.
  }
```

Looks like the so-called easy step is not so easy after all. There must be a better way. There must be a safer way. Let's have another look.

#### Alternative approach
If we look carefully in the above code, the problem lies, because we need to keep digging for all intermediate `key`. We could probably write a generalized function that takes in all the keys, and it keeps going in to find the final value.
```swift
func valueFor(keys: String..., inDictionary dict: [String: Any]) -> Any? {

}
```
That helps! Can we do better? Writing key names one by one is too prone to mistakes. What if you have a typo.

What about, we generate the all possible keys combination out of plist, and read the key.

An interesting approach would be to generate a `enum` whose `case` are the `key` of the plist. This way we can be sure, we won't any unwarranted mistakes in providing the key name. There are several ways this could be done, the approach I would like to try out is write a script to generate the `enum` from Plist. Since we are talking about iOS here, why not try scripting in `swift`. Swift is incredibly efficient for minimal tasks like this. There are several articles and talks about scripting in swift. You can checkout one of my talks [here](https://freesuraj.github.io/talks).
