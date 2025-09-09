#!/usr/bin/env ruby

require 'httparty'
require 'nokogiri'

class DigikalaHTMLAnalyzer
  include HTTParty
  base_uri 'https://www.digikala.com'

  def initialize
    @headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language' => 'fa,en-US;q=0.7,en;q=0.3',
      'Accept-Encoding' => 'gzip, deflate, br',
      'DNT' => '1',
      'Connection' => 'keep-alive',
      'Upgrade-Insecure-Requests' => '1'
    }
  end

  def analyze_search_page
    puts "🔍 Analyzing Digikala search page structure..."
    
    search_url = "/search/?q=laptop"
    
    begin
      response = self.class.get(search_url, 
        headers: @headers,
        timeout: 10,
        follow_redirects: true
      )
      
      if response.success?
        puts "✅ Successfully fetched search page"
        puts "📄 Response size: #{response.body.length} characters"
        
        # Save the HTML for inspection
        File.write('/tmp/digikala_search.html', response.body)
        puts "💾 Saved HTML to /tmp/digikala_search.html"
        
        # Parse and analyze structure
        doc = Nokogiri::HTML(response.body)
        
        puts "\n🔎 Analyzing HTML structure..."
        
        # Look for common product container patterns
        potential_selectors = [
          'div[data-testid*="product"]',
          'div[class*="product"]',
          'article',
          'div[class*="card"]',
          'div[class*="item"]',
          'a[href*="/product/"]',
          'div[class*="ProductCard"]',
          'div[class*="product-card"]',
          '.c-product-box',
          '[data-testid="product-card"]'
        ]
        
        potential_selectors.each do |selector|
          elements = doc.css(selector)
          if elements.any?
            puts "✅ Found #{elements.length} elements with selector: #{selector}"
            
            # Analyze first element
            if elements.first
              puts "   📋 First element classes: #{elements.first['class']}"
              puts "   📋 First element data attributes: #{elements.first.attributes.keys.select { |k| k.start_with?('data-') }}"
              
              # Look for text content that might be product names
              text_content = elements.first.text.strip
              if text_content.length > 10 && text_content.length < 200
                puts "   📝 Sample text: #{text_content[0..100]}..."
              end
            end
          else
            puts "❌ No elements found with selector: #{selector}"
          end
        end
        
        # Look for specific patterns
        puts "\n🔍 Looking for specific patterns..."
        
        # Find all links to products
        product_links = doc.css('a[href*="/product/"]')
        puts "🔗 Found #{product_links.length} product links"
        
        if product_links.any?
          puts "   📋 Sample product link: #{product_links.first['href']}"
          puts "   📋 Sample link text: #{product_links.first.text.strip[0..50]}..."
        end
        
        # Look for price patterns
        price_patterns = [
          'span[class*="price"]',
          'div[class*="price"]',
          'span:contains("تومان")',
          'div:contains("تومان")'
        ]
        
        price_patterns.each do |pattern|
          elements = doc.css(pattern)
          if elements.any?
            puts "💰 Found #{elements.length} potential price elements with: #{pattern}"
            sample_text = elements.first.text.strip
            puts "   📝 Sample: #{sample_text}" if sample_text.length < 100
          end
        end
        
      else
        puts "❌ Failed to fetch page. Status: #{response.code}"
        puts "Response: #{response.body[0..200]}..."
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
  
  def analyze_category_page
    puts "\n🏷️ Analyzing Digikala category page structure..."
    
    category_url = "/category/notebook-netbook-ultrabook/"
    
    begin
      response = self.class.get(category_url, 
        headers: @headers,
        timeout: 10,
        follow_redirects: true
      )
      
      if response.success?
        puts "✅ Successfully fetched category page"
        
        # Save the HTML for inspection
        File.write('/tmp/digikala_category.html', response.body)
        puts "💾 Saved HTML to /tmp/digikala_category.html"
        
        doc = Nokogiri::HTML(response.body)
        
        # Quick analysis
        product_links = doc.css('a[href*="/product/"]')
        puts "🔗 Found #{product_links.length} product links in category page"
        
      else
        puts "❌ Failed to fetch category page. Status: #{response.code}"
      end
      
    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
end

# Run the analysis
analyzer = DigikalaHTMLAnalyzer.new
analyzer.analyze_search_page
analyzer.analyze_category_page

puts "\n🏁 Analysis complete!"
puts "📁 Check /tmp/digikala_search.html and /tmp/digikala_category.html for detailed HTML structure"
