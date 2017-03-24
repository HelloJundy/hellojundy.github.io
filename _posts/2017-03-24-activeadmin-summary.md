
目前接触的两个项目都在用 Activeadmin 作为管理后台，趁最近没有那么忙总结一下ActiveAdmin 的使用情况。

---

## Contents
* Plugins
* I18n
* Form
* Todo

---

## Plugins

#### [chartkick](https://github.com/ankane/chartkick)
因为项目中的 Dashboard 都要求以图表的方式显示统计数据， 这里选用 chartkick,可以使用 ruby 代码画出漂亮的图表，十分方便。

dashboard.rb
```ruby
columns do
  column do
    text_node <%= line_chart data, height: '300px', library: line_chart_options %>
  end
end
```

`data` 可以是 Hash 或 Array, `library`参数可以定制各种样式

可以挑选适合的 js 库
* Chart.js
* Google Charts
* Highcharts

另外这个库也有 react , vue 的版本。

### Active Admin Plugins
* https://github.com/activeadmin-plugin
* https://github.com/activeadmin/activeadmin/wiki/Plugins

这里有一系列的 activeadmin plugins，下面挑出项目中用到的几个gem：

#### [active_admin_theme](https://github.com/activeadmin-plugins/active_admin_theme)

一个不错的 Theme ，给你的 active_admin 披上新衣。

#### [activeadmin_addons](https://github.com/platanus/activeadmin_addons)

拓展插件，增强 activeadmin
* Range Filter
* Select2
* Paperclip Integration
* AASM Integration
* Enum Integration
* Date Time Picker
* Color Picker
* Number Formatting
* List
* Boolean Values

下面说两个应用列子
##### 数据显示

```
index do
  # 显示图片
  image_column :cover
  # 显示数字
  number_column :price, as: :currency, unit: '￥'
  # 布尔值
  bool_column :is_hot
  # tag/status
  tag_column :online_state
  actions
end
```

一般项目中会使用七牛来做图片存储，我们可以稍稍做一些定制

qiniu_uploader.rb
```ruby
  def small_thumb_url
    url ? url + '?imageView2/2/w/50/h/50' : nil
  end

  def medium_thumb_url
    url ? url + '?imageView2/2/w/100/h/100' : nil
  end

  def thumb_url
    url ? url + '?imageView2/2/w/200/h/200' : nil
  end
```
config/initializers/active_admin_addons.rb
```ruby
require 'activeadmin_addons/support/custom_builder.rb'

module ActiveAdminAddons
  # for show qiniu storage image
  class QiniuImageBuilder < CustomBuilder
    def render
      return nil if data.nil?
      raise 'you need to pass a paperclip image attribute' unless data.respond_to?(:url)
      style = options.fetch(:style, nil)
      context.image_tag(data.send(style ? "#{style}_url" : 'url')) if data.present?
    end
  end

  module ::ActiveAdmin
    module Views
      class TableFor
        def qiniu_image_column(*args, &block)
          column(*args) { |model| QiniuImageBuilder.render(self, model, *args, &block) }
        end
      end
      class AttributesTable
        def qiniu_image_row(*args, &block)
          row(*args) { |model| QiniuImageBuilder.render(self, model, *args, &block) }
        end
      end
    end
  end
end
```
这样我们可以使用qiniu_image_column/qiniu_image_row 来显示七牛上不同尺寸的图片了

```
index do
  qiniu_image_row :cover, style: :small_thumb
  actions
end
show do
  attributes_table do
    qiniu_image_row :avatar, style: :thumb
  end
end
```

##### Select2 - tags
我们使用 as: :tags来实现多选功能：

```ruby
f.input :related_activity_ids, as: :tags, collection: Activity.online.approved.where.not(id: object.id), display_name: :title
```

但此处有个小坑，当我们选中了多个选项并保存，再次编辑的时候会发现多个 tag 变成了一个 tag。

显然 addons 并没有对结果进行处理，一股脑得将 tag_list 全填充进去了。

看文档发现 tagging 有 `value` 这个 option， 所以我们可以这样处理一下：

```ruby
f.input :related_activity_ids, as: :tags, collection: Activity.online,
value: f.object.related_activities.pluck(:id).join(","), display_name: :title
```

当然也可以用 `input_html: {value: f.object.related_activities.pluck(:id).join(",")}` 来实现。

#### [activeadmin-xls](https://github.com/beansmile/activeadmin-xls)

active_admin 本身有导出 CSV/XML/JSON 的功能，但是客户提出需要导出 xls 格式的文档。

上文提到的 active admin plugins 列表中的ActiveAdmin Axlsx 已经年久失修, 只支持 activeadmin (~> 0.6.0)，而项目中使用activeadmin (1.0.0.pre4)，现在最新是activeadmin (1.0.0.pre5)。

目前使用的activeadmin-xls，是在ActiveAdmin Axlsx 基础上再维护的一个gem。基本能够满足我们的需求：

* 定制需要导出的列
* 表头样式
* I18n

未满足的：
* 合并单元格
* 设置表格从第几行开始
* 设置每一列的宽度

最终决定fork这个 gem，做一些定制来实现上面的需求，目前此 gem 在 beansmile 的 github repository 上。

现在可以这样来实现我们的导出功能：

```ruby
xls(:i18n_scope => [:activerecord, :attributes, :activity],
      header_format: { horizontal_align: :center },
      body_format: { :text_wrap => true },
      start_row: 3,
      merge_cells: [
        { start_row: 2, start_col: 1, end_row: 2, end_col: 2 },
        { start_row: 2, start_col: 5, end_row: 2, end_col: 6 }
      ]
  ) do
    column :id, width: 10
end
```

### Form

使用 :input_html 设置表单项属性
使用 :wrapper_html 设置包裹着表单项的元素属性

```
form do |f|
    f.inputs do
      f.input :cancel_reason, :wrapper_html => {:style => 'display:none'}
      f.input :location, :input_html => { :style => 'display:none', :class => 'autogrow' }
    end
    f.buttons
  end
```

### I18n

在做 show 页面 tab title 的 I18n 的时候, 如果简单的使用I18n.t()来实现的话，会有样式错乱的 bug。

```ruby
show do
  tabs do
    tab I18n.t('active_admin.tabs.users') do
    end
  end
end
```

修改 build_menu_item 方法来支持 I18n

```ruby
ActiveAdmin::Views::Tabs.class_eval do
  def build_menu_item(title, options, &_block)
    options = options.reverse_merge({})
    li { link_to I18n.t(title), "##{title.parameterize}", options }
  end
end

```

admin.zh-CN.yml

```ruby
"zh-CN":
  active_admin:
    tabs:
      users: '报名情况'
```

现在可以这样写：

```ruby
show do
  tabs do
    tab 'active_admin.tabs.users' do
    end
  end
end
```

### Todo
show 页面

```ruby
show do
  tabs do
    attributes_table do
      row(:description){ |activity| activity.description.html_safe }
      row :start_time
      row :end_time
    end
  end
end
```

因为 description 保存的是富文本编辑器的内容，所以使用了 `html_safe` 来显示 html 标签。

但当 description 中包含了一个`<iframe>` 标签的时候，页面渲染将停留在 description，后面的 start_time， end_time 没有被渲染出来，存在页面渲染不完全的情况。

目前方案：
不使用 html_safe 方法，且将 description 用 `display:none`  隐藏掉，当页面渲染完成后，再用 jQuery 将 description的内容渲染出来。
