#!/usr/bin/env ruby

# Test script to demonstrate AI-powered product search system
# Run this from the backend directory with: ruby test_ai_system.rb

require_relative 'config/environment'

puts "🤖 AI-Powered Product Search System Demo"
puts "=" * 50

# Test 1: Standard search
puts "\n📱 Test 1: Standard Persian Query"
puts "Query: 'گوشی سامسونگ ارزان'"

controller = Api::V1::ChatbotController.new
params = ActionController::Parameters.new({
  message: "گوشی سامسونگ ارزان"
})

controller.params = params

begin
  # Simulate the chat method logic
  message = params[:message]
  
  # Test keyword extraction
  keywords = controller.send(:extract_product_keywords, message)
  puts "Extracted keywords: #{keywords}"
  
  # Test product search intent
  should_search = controller.send(:should_search_products?, message)
  puts "Should search for products: #{should_search}"
  
  # Test query analysis (new enhanced features)
  if controller.respond_to?(:analyze_query_metadata, true)
    metadata = controller.send(:analyze_query_metadata, message)
    puts "Query metadata: #{metadata.inspect}"
  end
  
rescue => e
  puts "Error in test: #{e.message}"
end

# Test 2: AI prompt generation
puts "\n🧠 Test 2: AI Prompt Generation"
puts "Testing enhanced prompt service..."

begin
  if defined?(EnhancedPromptService)
    # Test search optimization prompt
    optimization_prompt = EnhancedPromptService.generate_search_optimization_prompt(
      "لپ تاپ گیمینگ با RTX",
      { language: 'persian', budget: 'flexible' }
    )
    
    puts "Search optimization prompt generated (length: #{optimization_prompt.length} chars)"
    puts "Sample: #{optimization_prompt[0..200]}..."
  else
    puts "EnhancedPromptService not available"
  end
rescue => e
  puts "Error testing prompt generation: #{e.message}"
end

# Test 3: Intelligent search service
puts "\n🔍 Test 3: Intelligent Search Capabilities"

begin
  if defined?(IntelligentSearchService)
    search_service = IntelligentSearchService.new
    
    # Test query optimization (without actual search)
    test_query = "گوشی اپل ارزان"
    
    # Test brand extraction
    brands = search_service.send(:extract_brands, test_query)
    puts "Detected brands: #{brands}"
    
    # Test category extraction  
    categories = search_service.send(:extract_categories, test_query)
    puts "Detected categories: #{categories}"
    
    # Test rule-based query generation
    optimized_queries = search_service.send(:generate_rule_based_queries, test_query)
    puts "Optimized search queries: #{optimized_queries}"
    
  else
    puts "IntelligentSearchService not available"
  end
rescue => e
  puts "Error testing intelligent search: #{e.message}"
end

# Test 4: OpenRouter service enhancements
puts "\n🌐 Test 4: Enhanced OpenRouter Service"

begin
  openrouter = OpenrouterService.new
  
  # Test fallback response generation
  mock_products = [
    {
      name: "Samsung Galaxy A54 5G",
      price: "۲۸,۵۰۰,۰۰۰ تومان", 
      rating: "۴.۲ از ۵",
      brand: "Samsung",
      url: "https://digikala.com/product/12345"
    }
  ]
  
  fallback_response = openrouter.send(:generate_fallback_response, 
    "گوشی سامسونگ میخوام", 
    mock_products
  )
  
  puts "Fallback response generated (length: #{fallback_response.length} chars)"
  puts "Sample: #{fallback_response[0..200]}..."
  
  # Test product summary generation
  if openrouter.respond_to?(:generate_product_summary, true)
    summary = openrouter.send(:generate_product_summary, mock_products)
    puts "Product summary: #{summary.strip}"
  end
  
rescue => e
  puts "Error testing OpenRouter service: #{e.message}"
end

# Test 5: Persian language processing
puts "\n🇮🇷 Test 5: Persian Language Processing"

test_queries = [
  "گوشی سامسونگ ارزان میخوام",
  "laptop gaming for work",
  "لپ تاپ گیمینگ samsung galaxy"
]

test_queries.each_with_index do |query, index|
  puts "\nQuery #{index + 1}: \"#{query}\""
  
  # Test language detection
  persian_chars = query.scan(/[\u0600-\u06FF]/).length
  english_chars = query.scan(/[a-zA-Z]/).length
  total_chars = persian_chars + english_chars
  
  if total_chars > 0
    persian_ratio = persian_chars.to_f / total_chars
    language = if persian_ratio > 0.6
      'persian'
    elsif persian_ratio < 0.2  
      'english'
    else
      'mixed'
    end
    
    puts "  Detected language: #{language} (#{(persian_ratio * 100).round(1)}% Persian)"
  end
  
  # Test keyword extraction
  controller = Api::V1::ChatbotController.new
  keywords = controller.send(:extract_product_keywords, query)
  puts "  Extracted keywords: #{keywords}"
end

puts "\n✅ AI System Demo Complete!"
puts "\nKey Features Demonstrated:"
puts "- Persian/English keyword extraction"
puts "- Intelligent search intent detection"  
puts "- AI prompt generation for better responses"
puts "- Enhanced product search with multiple strategies"
puts "- Contextual fallback responses"
puts "- Multi-language query processing"

puts "\nTo test the full system:"
puts "1. Start the Rails backend: bin/rails server -p 3001"
puts "2. Start the Nuxt frontend: cd frontend && npm run dev"
puts "3. Visit http://localhost:3000 and try queries like:"
puts "   - گوشی سامسونگ ارزان"
puts "   - لپ تاپ گیمینگ زیر ۳۰ میلیون"
puts "   - هدفون بی سیم برای ورزش"