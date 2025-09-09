class Api::V1::ChatbotController < ApplicationController
  def chat
    message = params[:message]
    product_query = params[:product_query]

    if message.blank?
      render json: { error: "Message cannot be blank" }, status: :bad_request
      return
    end

    Rails.logger.info "Processing chat message: #{message}"

    # Search for products if the message seems to be about products
    context = nil
    search_term = nil
    
    if should_search_products?(message) || product_query.present?
      search_term = product_query.present? ? product_query : extract_product_keywords(message)
      
      if search_term.present?
        Rails.logger.info "Searching for products with term: #{search_term}"
        
        digikala_service = DigikalaScrapingService.new
        context = digikala_service.search_products(search_term, 30)
        
        Rails.logger.info "Found #{context&.length || 0} products"
      end
    end

    # Get AI response with product context
    openrouter_service = OpenrouterService.new
    ai_response = openrouter_service.chat_completion(message, context)

    Rails.logger.info "Generated AI response of length: #{ai_response&.length || 0}"

    render json: {
      response: ai_response,
      products: context || [],
      searched_for: search_term,
      product_count: context&.length || 0
    }
  rescue => e
    Rails.logger.error "Chatbot error: #{e.message}"
    render json: { 
      error: "Sorry, I encountered an error. Please try again.",
      response: "I'm having trouble processing your request right now. Please try again in a moment."
    }, status: :internal_server_error
  end

  private

  def should_search_products?(message)
    product_keywords = [
      # Purchase-related terms
      'خرید', 'buy', 'purchase', 'product', 'محصول', 'قیمت', 'price',
      
      # Electronics
      'laptop', 'لپ تاپ', 'لپتاپ', 'phone', 'گوشی', 'موبایل', 'تلویزیون', 'tv',
      'headphone', 'هدفون', 'هندزفری', 'کامپیوتر', 'computer', 'تبلت', 'tablet',
      'ساعت هوشمند', 'smartwatch', 'مانیتور', 'monitor', 'کیبورد', 'keyboard',
      'ماوس', 'mouse', 'اسپیکر', 'speaker', 'دوربین', 'camera',
      
      # Personal care & grooming
      'ماشین اصلاح', 'اصلاح', 'shaver', 'trimmer', 'razor', 'صورت', 'موی',
      'برقی', 'شارژی', 'ضد آب',
      
      # Home appliances
      'یخچال', 'fridge', 'ماشین لباسشویی', 'washing machine', 'فر', 'oven',
      'مایکروویو', 'microwave', 'جاروبرقی', 'vacuum', 'اتو', 'iron',
      
      # Fashion & accessories
      'کتاب', 'book', 'clothes', 'لباس', 'کفش', 'shoe', 'کیف', 'bag',
      'عینک', 'glasses', 'ساعت', 'watch',
      
      # Sports & outdoor
      'ورزشی', 'sport', 'دوچرخه', 'bike', 'توپ', 'ball',
      
      # Beauty & health
      'زیبایی', 'beauty', 'آرایش', 'makeup', 'عطر', 'perfume', 'کرم', 'cream',
      'شامپو', 'shampoo', 'مکمل', 'supplement',
      
      # Kitchen & dining
      'آشپزخانه', 'kitchen', 'قابلمه', 'pot', 'ماهیتابه', 'pan', 'چاقو', 'knife',
      'بشقاب', 'plate', 'لیوان', 'glass',
      
      # Generic product indicators
      'بهترین', 'best', 'پیشنهاد', 'recommend', 'suggest', 'خوب', 'good',
      'ارزان', 'cheap', 'گران', 'expensive', 'quality', 'کیفیت'
    ]
    
    product_keywords.any? { |keyword| message.downcase.include?(keyword.downcase) }
  end

  def extract_product_keywords(message)
    # Enhanced keyword extraction to capture brands and specific products in Persian
    message_lower = message.downcase
    
    # Define brand names (keep Persian names as primary)
    persian_brands = [
      'سامسونگ', 'آیفون', 'اپل', 'هواوی', 'شیائومی', 'ال جی', 'سونی', 'نوکیا',
      'ایسوس', 'لنوو', 'دل', 'اچ پی', 'ام اس آی', 'ایسر'
    ]
    
    # Also include common English brand names that might be used
    english_brands = [
      'samsung', 'apple', 'iphone', 'huawei', 'xiaomi', 'lg', 'sony', 'nokia',
      'asus', 'lenovo', 'dell', 'hp', 'msi', 'acer'
    ]
    
    # Define product types in Persian with better coverage
    persian_products = [
      # Electronics
      'گوشی', 'موبایل', 'لپ تاپ', 'لپتاپ', 'تلویزیون', 'هدفون', 'هندزفری',
      'تبلت', 'ساعت هوشمند', 'کیبورد', 'ماوس', 'مانیتور', 'دوربین',
      'کامپیوتر', 'اسپیکر', 'پاور بانک', 'شارژر',
      
      # Personal care
      'ماشین اصلاح صورت', 'ماشین اصلاح', 'اصلاح صورت', 'ریش تراش',
      'تریمر', 'اپیلاتور', 'سشوار', 'اتو مو',
      
      # Home appliances  
      'یخچال', 'ماشین لباسشویی', 'فر', 'مایکروویو', 'جاروبرقی', 'اتو',
      'کولر', 'بخاری', 'پنکه',
      
      # Fashion & accessories
      'کتاب', 'لباس', 'کفش', 'کیف', 'عینک', 'ساعت', 'جواهرات',
      
      # Sports & outdoor
      'دوچرخه', 'توپ', 'کفش ورزشی', 'لباس ورزشی',
      
      # Beauty & health
      'عطر', 'کرم', 'شامپو', 'آرایش', 'مکمل', 'ویتامین',
      
      # Kitchen
      'قابلمه', 'ماهیتابه', 'چاقو', 'بشقاب', 'لیوان', 'فنجان'
    ]
    
    # Extract brands from message (Persian first, then English)
    detected_brands = []
    persian_brands.each do |brand|
      if message_lower.include?(brand)
        detected_brands << brand
      end
    end
    
    # If no Persian brands found, check English brands
    if detected_brands.empty?
      english_brands.each do |brand|
        if message_lower.include?(brand)
          detected_brands << brand
        end
      end
    end
    
    # Extract product types from message
    detected_products = []
    persian_products.each do |product|
      if message_lower.include?(product)
        detected_products << product
      end
    end
    
    # Build search query in Persian
    search_terms = []
    
    # If we have both brand and product type
    if detected_brands.any? && detected_products.any?
      # Combine product type with brand (e.g., "گوشی سامسونگ")
      detected_products.each do |product|
        detected_brands.each do |brand|
          search_terms << "#{product} #{brand}"
        end
      end
    elsif detected_brands.any?
      # Just brand names
      search_terms.concat(detected_brands)
    elsif detected_products.any?
      # Just product types
      search_terms.concat(detected_products)
    else
      # Fallback: extract meaningful Persian words, avoiding common stopwords
      persian_stopwords = [
        'و', 'یا', 'که', 'را', 'در', 'با', 'از', 'به', 'تا', 'برای',
        'خوب', 'بهترین', 'پیشنهاد', 'بده', 'کن', 'میخوام', 'میخواهم',
        'لطفا', 'help', 'good', 'best', 'please', 'want', 'need', 'the', 'a', 'an'
      ]
      
      words = message.split(/\s+/)
      meaningful_words = words.select do |word|
        # Keep words longer than 2 characters and not common stopwords
        word.length > 2 && 
        !persian_stopwords.include?(word.downcase)
      end
      
      search_terms = meaningful_words.take(2)
    end
    
    # Return the best search term, fallback to "گوشی" for mobile-related queries
    result = search_terms.first
    
    # If we detected it's about phones but no specific brand, use generic phone term
    if result.nil? && (message_lower.include?('گوشی') || message_lower.include?('موبایل') || message_lower.include?('phone'))
      result = 'گوشی'
    end
    
    result || 'محصول'
  end
end
