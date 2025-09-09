#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

def test_chatbot_api(message)
  uri = URI('http://localhost:3001/api/v1/chatbot/chat')
  
  http = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request.body = { message: message }.to_json
  
  puts "🔍 Testing message: \"#{message}\""
  puts "📡 Sending request to: #{uri}"
  
  response = http.request(request)
  
  if response.code == '200'
    data = JSON.parse(response.body)
    
    puts "✅ Success! Status: #{response.code}"
    puts "🤖 AI Response: #{data['response']}"
    puts "📦 Products found: #{data['product_count'] || 0}"
    puts "🔎 Searched for: #{data['searched_for']}"
    
    if data['products'] && data['products'].any?
      puts "\n📱 Product Details:"
      data['products'].each_with_index do |product, index|
        puts "  #{index + 1}. #{product['name']}"
        puts "     💰 قیمت: #{product['price']}"
        puts "     ⭐ امتیاز: #{product['rating']}"
        puts "     🏷️ برند: #{product['brand']}"
        puts "     🔗 لینک: #{product['url']}"
        puts ""
      end
    end
  else
    puts "❌ Error! Status: #{response.code}"
    puts "Response: #{response.body}"
  end
  
  puts "=" * 80
  puts ""
end

# Test different queries
puts "🚀 Testing Product Purchase Assistant API\n"
puts "=" * 80

test_chatbot_api("لپ تاپ برای کار می‌خوام")
test_chatbot_api("بهترین گوشی زیر ۲۰ میلیون تومان")
test_chatbot_api("هدفون گیمینگ خوب معرفی کن")
test_chatbot_api("laptop for programming")

puts "🏁 Testing completed!"
