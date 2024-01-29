Welcome to robloxlang!
First, things first => Imports. 
Yep, you gotta do em yourself if you wanna use it off ROBLOX, sorry.
```
Hello, world!

item { 
  function main() { 
    print("Hello, world!");
  }
}
```
```

Variables

item {
  \# Variables can be here too
  function main() { 
    var h = 15.0; \# replace var with const for constants
    print(h);
  }
}
```
```

Ifs, whiles, and fors are exactly like JS, but you use var instead of let.

Functions

item { 
  function main() { 
    print(B());
  }
  function B() { 
    print("B");
  }
}
```
```js
item {
  function main() {
    var lambda = $() {
      return 10;
    };

    switch (123) {
      case 123 {
        print("Hi!");
      }
      default {
        print("Hi!");
      }
    }

    var matchexpr = switch 123 {
      case 123 => "Hi";
      default => "Hi";
    }
  }
}
```
