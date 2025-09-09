class DigikalaScrapingService
  require 'selenium-webdriver'
  require 'nokogiri'

  def initialize
    @driver = nil
  end

  def search_products(query, limit = 10)
    Rails.logger.info "Searching Digikala for: #{query} using browser automation"
    
    products = []
    
    begin
      setup_driver
      products = scrape_with_browser(query, limit)
    rescue => e
      Rails.logger.error "Browser automation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      cleanup_driver
    end
    
    products.take(limit)
  end

  private

  def setup_driver
    options = Selenium::WebDriver::Chrome::Options.new
    
    # Configure Chrome for headless mode and anti-detection
    options.add_argument('--headless=new') # Use new headless mode
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-gpu')
    options.add_argument('--window-size=1920,1080')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-plugins')
    options.add_argument('--disable-images') # Speed up loading
    
    # Set user agent to look like a real browser
    options.add_argument('--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    # Additional preferences for better compatibility
    options.add_preference('profile.default_content_setting_values.notifications', 2)
    options.add_preference('profile.default_content_settings.popups', 0)
    options.add_preference('profile.managed_default_content_settings.images', 2)
    
    # Set binary location if needed
    options.binary = '/usr/bin/google-chrome-stable'
    
    begin
      @driver = Selenium::WebDriver.for :chrome, options: options
      @driver.manage.timeouts.implicit_wait = 10
      @driver.manage.timeouts.page_load = 30
      Rails.logger.info "Chrome driver initialized successfully"
    rescue => e
      Rails.logger.error "Failed to initialize Chrome driver: #{e.message}"
      # Try Firefox as fallback
      setup_firefox_driver
    end
  end

  def setup_firefox_driver
    options = Selenium::WebDriver::Firefox::Options.new
    
    # Configure Firefox for headless mode
    options.add_argument('--headless')
    options.add_argument('--width=1920')
    options.add_argument('--height=1080')
    
    # Set user agent
    options.add_preference('general.useragent.override', 'Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0')
    
    begin
      @driver = Selenium::WebDriver.for :firefox, options: options
      @driver.manage.timeouts.implicit_wait = 10
      @driver.manage.timeouts.page_load = 30
      Rails.logger.info "Firefox driver initialized as fallback"
    rescue => e
      Rails.logger.error "Failed to initialize Firefox driver: #{e.message}"
      raise "No suitable browser driver available"
    end
  end

  def cleanup_driver
    if @driver
      @driver.quit
      @driver = nil
      Rails.logger.info "Browser driver cleaned up"
    end
  end

  def scrape_with_browser(query, limit)
    # Try different approaches to get product data
    products = []
    
    # Method 1: Try search page
    products = scrape_search_page(query, limit)
    
    # Method 2: Try category page if search fails
    if products.empty?
      products = scrape_category_page(query, limit)
    end
    
    # Method 3: Try alternative search approach
    if products.empty?
      products = scrape_alternative_search(query, limit)
    end
    
    Rails.logger.info "Successfully scraped #{products.length} products"
    products
  end

  def scrape_search_page(query, limit)
    search_url = "https://www.digikala.com/search/?q=#{URI.encode_www_form_component(query)}"
    
    Rails.logger.info "Navigating to: #{search_url}"
    
    begin
      @driver.navigate.to(search_url)
      
      # Wait for page to load
      sleep(3)
      
      # Take screenshot for debugging
      @driver.save_screenshot('/tmp/digikala_search_screenshot.png') rescue nil
      
      # Get page source
      page_source = @driver.page_source
      File.write('/tmp/digikala_browser_source.html', page_source) rescue nil
      
      # Parse with Nokogiri
      doc = Nokogiri::HTML(page_source)
      
      Rails.logger.info "Page loaded, analyzing content..."
      
      # Look for product containers with multiple selector strategies
      products = extract_products_from_page(doc, limit)
      
      Rails.logger.info "Found #{products.length} products from search page"
      products
      
    rescue => e
      Rails.logger.error "Error scraping search page: #{e.message}"
      []
    end
  end

  def scrape_category_page(query, limit)
    category_mappings = {
      /laptop|لپ تاپ/i => 'https://www.digikala.com/category/notebook-netbook-ultrabook/',
      /phone|گوشی|موبایل/i => 'https://www.digikala.com/category/mobile-phone/',
      /headphone|هدفون/i => 'https://www.digikala.com/category/headphone/',
      /tablet|تبلت/i => 'https://www.digikala.com/category/tablet/'
    }
    
    category_url = nil
    category_mappings.each do |pattern, url|
      if query.match?(pattern)
        category_url = url
        break
      end
    end
    
    return [] unless category_url
    
    Rails.logger.info "Navigating to category: #{category_url}"
    
    begin
      @driver.navigate.to(category_url)
      sleep(3)
      
      # Get page source
      page_source = @driver.page_source
      doc = Nokogiri::HTML(page_source)
      
      products = extract_products_from_page(doc, limit)
      
      Rails.logger.info "Found #{products.length} products from category page"
      products
      
    rescue => e
      Rails.logger.error "Error scraping category page: #{e.message}"
      []
    end
  end

  def scrape_alternative_search(query, limit)
    # Try mobile version which might be simpler
    mobile_url = "https://m.digikala.com/search/?q=#{URI.encode_www_form_component(query)}"
    
    Rails.logger.info "Trying mobile version: #{mobile_url}"
    
    begin
      @driver.navigate.to(mobile_url)
      sleep(2)
      
      page_source = @driver.page_source
      doc = Nokogiri::HTML(page_source)
      
      products = extract_products_from_page(doc, limit)
      
      Rails.logger.info "Found #{products.length} products from mobile page"
      products
      
    rescue => e
      Rails.logger.error "Error scraping mobile page: #{e.message}"
      []
    end
  end

  def extract_products_from_page(doc, limit)
    products = []
    
    Rails.logger.info "Analyzing page structure for products..."
    
    # Multiple selector strategies for finding products - prioritize link containers
    product_selectors = [
      # Direct product links (highest priority)
      'a[href*="/product/"]',
      
      # Modern React/Next.js patterns
      '[data-testid*="product"]',
      '[class*="ProductCard"]',
      '[class*="product-card"]',
      '[class*="ProductItem"]',
      
      # Traditional patterns
      '.c-product-box',
      '.product-list-item',
      '.product-item',
      
      # Generic containers that might contain products
      'article',
      '[role="article"]',
      '.card',
      '[class*="card"]'
    ]
    
    found_elements = nil
    used_selector = nil
    
    product_selectors.each do |selector|
      elements = doc.css(selector)
      if elements.length > 0
        found_elements = elements
        used_selector = selector
        Rails.logger.info "Found #{elements.length} elements with selector: #{selector}"
        break
      end
    end
    
    if found_elements.nil? || found_elements.empty?
      Rails.logger.warn "No product elements found with any selector"
      
      # Fallback: look for any links to products
      product_links = doc.css('a[href*="/product/"]')
      Rails.logger.info "Found #{product_links.length} product links as fallback"
      
      if product_links.any?
        # Extract basic info from product links
        product_links.first(limit).each do |link|
          begin
            product = extract_basic_product_info(link)
            products << product if product
          rescue => e
            Rails.logger.error "Error extracting basic product info: #{e.message}"
          end
        end
      end
      
      return products
    end
    
    # Extract detailed product information
    found_elements.first(limit).each_with_index do |element, index|
      begin
        product = extract_detailed_product_info(element)
        products << product if product
      rescue => e
        Rails.logger.error "Error extracting product #{index}: #{e.message}"
      end
    end
    
    Rails.logger.info "Successfully extracted #{products.length} products"
    products
  end

  def extract_detailed_product_info(element)
    # Extract product name
    name_selectors = [
      'h2', 'h3', 'h4',
      '[class*="title"]',
      '[class*="name"]',
      '[data-testid*="title"]',
      'a[href*="/product/"]'
    ]
    
    name = extract_text_by_selectors(element, name_selectors)
    return nil if name.blank?
    
    # Extract price
    price_selectors = [
      '[class*="price"]',
      '[data-testid*="price"]',
      'span:contains("تومان")',
      'div:contains("تومان")'
    ]
    
    price = extract_text_by_selectors(element, price_selectors)
    price = "قیمت موجود نیست" if price.blank?
    
    # Extract rating
    rating_selectors = [
      '[class*="rating"]',
      '[class*="star"]',
      '[data-testid*="rating"]'
    ]
    
    rating = extract_text_by_selectors(element, rating_selectors)
    rating = "بدون امتیاز" if rating.blank?
    
    # Extract URL - try multiple approaches
    url_selectors = [
      'a[href*="/product/"]',
      'a[href*="/dp/"]'  # Alternative URL pattern
    ]
    
    url = extract_href_by_selectors(element, url_selectors)
    
    # If no URL found in immediate element, search the entire element HTML
    if url.blank?
      element_html = element.to_s
      # Look for any href containing /product/
      url_match = element_html.match(/href=["']([^"']*\/product\/[^"']*)["']/)
      if url_match
        url = url_match[1]
        Rails.logger.debug "Found URL in HTML content: #{url}"
      end
    end
    
    # If still no URL, try to find the first link in the element
    if url.blank?
      first_link = element.css('a[href]').first
      if first_link && first_link['href']
        candidate_url = first_link['href']
        # Only use it if it looks like a product URL
        if candidate_url.include?('/product/') || candidate_url.include?('/dp/')
          url = build_full_url(candidate_url)
          Rails.logger.debug "Found URL from first link: #{url}"
        end
      end
    end
    
    # Log the final URL for debugging
    Rails.logger.debug "Final product URL: #{url}"
    
    # Return nil if no valid product URL found instead of fallback to generic URL
    return nil if url.blank?
    
    # Extract brand
    brand_selectors = [
      '[class*="brand"]',
      '[data-testid*="brand"]'
    ]
    
    brand = extract_text_by_selectors(element, brand_selectors)
    brand = "نامشخص" if brand.blank?
    
    # Extract image
    image_url = extract_image_url(element)
    
    {
      name: clean_text(name),
      price: clean_text(price),
      rating: clean_text(rating),
      brand: clean_text(brand),
      url: url,
      image: image_url,
      description: generate_description(name, brand)
    }
  end

  def extract_basic_product_info(link_element)
    name = link_element.text.strip
    return nil if name.blank?
    
    url = link_element['href']
    if url.present? && !url.start_with?('http')
      url = "https://www.digikala.com#{url}"
    end
    
    {
      name: clean_text(name),
      price: "قیمت موجود نیست",
      rating: "بدون امتیاز",
      brand: "نامشخص",
      url: url || "https://www.digikala.com",
      image: "https://dkstatics-public.digikala.com/digikala-products/placeholder.jpg",
      description: "محصول از دیجی‌کالا"
    }
  end

  def extract_text_by_selectors(element, selectors)
    selectors.each do |selector|
      found_element = element.css(selector).first
      if found_element
        text = found_element.text.strip
        return text unless text.blank?
      end
    end
    nil
  end

  def extract_href_by_selectors(element, selectors)
    Rails.logger.debug "Trying to extract URL from element with selectors: #{selectors.join(', ')}"
    
    # First, try to find the element if it's wrapped in a link
    if element.name == 'a' && element['href']
      href = element['href']
      Rails.logger.debug "Element itself is a link: #{href}"
      return build_full_url(href)
    end
    
    # Check if element is inside a parent link (most common case for Digikala)
    parent = element.parent
    while parent && parent.name != 'html'
      if parent.name == 'a' && parent['href']
        href = parent['href']
        Rails.logger.debug "Found URL in parent link: #{href}"
        return build_full_url(href)
      end
      parent = parent.parent
    end
    
    # Try each selector
    selectors.each do |selector|
      found_elements = element.css(selector)
      Rails.logger.debug "Selector '#{selector}' found #{found_elements.length} elements"
      
      found_elements.each do |found_element|
        if found_element['href']
          href = found_element['href']
          Rails.logger.debug "Found URL with selector '#{selector}': #{href}"
          return build_full_url(href)
        end
      end
    end
    
    # Fallback: search for any link within the element
    all_links = element.css('a[href]')
    Rails.logger.debug "Fallback: found #{all_links.length} total links in element"
    
    all_links.each do |link|
      href = link['href']
      if href && (href.include?('/product/') || href.include?('/dp/'))
        Rails.logger.debug "Found product URL in fallback: #{href}"
        return build_full_url(href)
      end
    end
    
    # Last resort: parse element HTML with regex
    element_html = element.to_s
    url_match = element_html.match(/href=["']([^"']*\/product\/[^"']*)["']/)
    if url_match
      href = url_match[1]
      Rails.logger.debug "Found URL via regex: #{href}"
      return build_full_url(href)
    end
    
    Rails.logger.debug "No URL found with any method"
    nil
  end

  def build_full_url(href)
    return nil if href.blank?
    
    if href.start_with?('http')
      href
    elsif href.start_with?('/')
      "https://www.digikala.com#{href}"
    else
      "https://www.digikala.com/#{href}"
    end
  end

  def extract_image_url(element)
    img_selectors = [
      'img[src*="dkstatics"]',
      'img[data-src*="dkstatics"]',
      'img'
    ]
    
    img_selectors.each do |selector|
      img_element = element.css(selector).first
      if img_element
        return img_element['src'] if img_element['src']
        return img_element['data-src'] if img_element['data-src']
      end
    end
    
    "https://dkstatics-public.digikala.com/digikala-products/placeholder.jpg"
  end

  def clean_text(text)
    return "" if text.nil?
    
    text.gsub(/\s+/, ' ')
        .gsub(/\n/, ' ')
        .strip
        .gsub(/[^\u0600-\u06FF\u0660-\u0669\u06F0-\u06F9a-zA-Z0-9\s\-\(\)\.\,\/]/, '')
  end

  def generate_description(name, brand)
    "محصول #{brand} - #{name.split.first(3).join(' ')}"
  end
end