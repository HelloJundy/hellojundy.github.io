require "open-uri"
require 'json'
uri = 'https://api.douban.com/v2/book/user/119280372/collections'
html_response = nil
open(uri) do |http|
  html_response = http.read
end
jayce = JSON.parse(html_response)
books = jayce['collections']
html = ""
books.each do |book|
  if book['status'] == "read"
    html += "<li><br><h3><a class='post-link' href=#{book['book']['alt']}>#{book['book']['title']}</a><span class='author'>#{book['book']['author'].join('，')}</span></h3><img src= #{book['book']['image']}><div class='comment'>#{book['comment'].gsub(/\n/,'<br/>') if book['comment']}</div><br><span class='post-meta'>#{book['updated']}</span><hr id='line'></li>"
  end
end

p html
