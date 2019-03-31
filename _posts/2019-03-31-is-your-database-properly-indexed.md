---
layout: post
title:  "[译] 你的 Rails 应用正确建立索引了吗"
categories: ruby
---

我的 Rails 应用正常流畅的工作了好几个月后，随着产品的增长和用户开始涌入，Web 请求开始变得缓慢，数据库 CPU 使用率开始上升。然而我并没有做过什么更改，为什么应用就开始变慢了？

这个问题是否有解决办法? 或者说在 Rails 下不支持大规模地扩展？

### 是什么让 Rails 程序变慢？

虽说程序变缓慢的原因有很多，但数据库查询通常在应用程序性能表现中扮演着举足轻重的角色。例如将过多的数据加载到内存中，N + 1 查询，缺少缓存等，其中缺少适当的数据库索引是让查询变缓慢的罪魁祸首。

没有为**外键**、**常用搜索字段**、**需要排序的字段**等添加索引可能会产生巨大的差异。在只有数千条记录的表中可能无足轻重，几乎无法察觉；但是当你访问数百万条记录时，查询缓慢的问题将暴露无遗。

### 数据库索引扮演的角色

当你创建数据库字段时, 需要重点考虑是否将会根据该字段来查找或检索数据。

举个列子，让我们看一下[Semaphore](https://semaphoreci.com/)的内部结构。我们有一个 `Project` `Model`, 每一个 `Project` 有一个 `name` 属性。 当有人要在[Semaphore](https://semaphoreci.com/)中访问 `Project` 时，例如：https://semaphoreci.com/renderedtext/test-boosters, 在控制器中第一件要做的事情就是通过 `name` 查找 `project` :

```
project = Project.find_by_name(params[:name])
```

如果没有添加索引，数据库引擎将逐条检索 `projects` 表中的每一条数据，直到找到匹配项。

但是如果我们在 `projects` 添加索引，查询将会快很多。如下：

```
class IndexProjectsOnName < ActiveRecord::Migration
  def change
    add_index :projects, :name
  end
end
```

把索引想象成书末的索引部分可以让你让好的了解它。如果你想要找到书中的一个单词，你可以选择把整本书读完然后找到那个单词，也可以打开索引部分
, 通过按照字母顺序排列的重要单词列表，找到该单词并得到该单词所在的页面。

### 什么时候需要建立索引？

根据以往经验得出的一个建议是为 SQL 查询的 `WHERE` 、`HAVING` 、
`ORDER BY` 部分中引用的所有内容创建数据库索引。

#### 唯一性索引

任何基于唯一值字段的查询都应该建立索引。

例如一下查询：

```
User.find_by_username("shiroyasha")
User.find_by_email("support@semaphoreci.com")
```

将受益于为`username`和 `email` 字段添加的索引：

```
add_index :users, :username
add_index :users, :email
```

#### 外键索引

如果你有 `belongs_to` 或者 `has_many` 关联关系，你需要为外键添加索引以优化查询速度。

举个列子，我们有 `branches` 属于 `projects`:

```
class Project < ActiveRecord::Base
  has_many :branches
end

class Branch < ActiveRecord::Base
  belongs_to :project
end
```

为了更快的查询，我们需要添加如下索引

```
add_index :branches, :project_id
```

在多态关联中，`Project` 的所有者可以是 `User`，也可以是`Organization`:

```
class Organization < ActiveRecord::Base
  has_many :projects, :as => :owner
end

class User < ActiveRecord::Base
  has_many :projects, :as => :owner
end

class Project < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
end
```

我们需要确保建立一个双索引：

```
# Bad: This will not improve the lookup speed

add_index :projects, :owner_id
add_index :projects, :owner_type

# Good: This will create the proper index

add_index :projects, [:owner_id, :owner_type]
```

#### 排序字段索引

可以为经常需要排序的字段建立专用索引来提高查询速度。

```
Build.order(:updated_at).take(10)
```

为 `updated_at` 添加专用索引

```
add_index :updated_at
```

### 有必要总是使用索引吗？

为重要的字段添加索引可以极大的提高应用程序的性能，但有时候效果甚微，甚至让应用程序变的更慢。

例如:

1. 为需要经常插入/删除记录的表添加索引可能会对数据库的性能产生负面影响。(索引带来的方便不是免费的，每一次的插入/删除都需要维护索引)
2. 具有海量数据的表需要为索引提供能多的存储空间。

原文 [Faster Rails: Is Your Database Properly Indexed?](https://semaphoreci.com/blog/2017/05/09/faster-rails-is-your-database-properly-indexed.html)
