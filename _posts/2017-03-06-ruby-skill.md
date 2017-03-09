---
layout: post
title:  "Ruby/Rails 技巧"
categories: ruby
---

记录运用到的一些技巧，不断更新。

#### 1. 构造 hash

```
hash = Hash['k1', 'v1', 'k2', 'v2']
=> {"k1"=>"v1", "k2"=>"v2"}
```

#### 2. 操作单数对象和数组对象用同样的方式

```
obj  = 1
obj_arr = [1, 2, 3]

[*obj]     # => [1]
[*obj_arr] # => [1, 2, 3]
```

使用Array()也可以得到一样的效果

#### 3. 对数组操作，最后展开

```
[[1, 2], [3, 4]].flat_map { |e| e + [100] }
=> [1, 2, 100, 3, 4, 100]
```

#### 4. 数组分组

```
(1..10).each_slice(3) { |a| p a }
=>  [1, 2, 3]
    [4, 5, 6]
    [7, 8, 9]
    [10]
```

#### 5. truncate()
Truncates a given text after a given length if text is longer than length:

```
"hello world".truncate(8)
=> "hello..."

"hello world, hello ruby".truncate(17,  omission: '... (continued)')
=> "he... (continued)"

# truncate_word()
"hello world, hello ruby".truncate_words(2)
=> "hello world,..."
```

#### 6. The reverse of camelize

```
'ActiveModel'.underscore
=> "active_model"

'ActiveModel::Errors'.underscore
=> "active_model/errors"
```
