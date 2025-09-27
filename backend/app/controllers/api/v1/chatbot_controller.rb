class Api::V1::ChatbotController < ApplicationController
  def chat
    message = params[:message]
    product_query = params[:product_query]
    use_ai_optimization = params[:ai_optimization] != 'false' # Default to true

    if message.blank?
      render json: { error: "Message cannot be blank" }, status: :bad_request
      return
    end

    Rails.logger.info "Processing chat message: #{message} (AI optimization: #{use_ai_optimization})"

    # Search for products if the message seems to be about products
    context = nil
    search_term = nil
    search_metadata = {}
    
    if should_search_products?(message) || product_query.present?
      if use_ai_optimization
        # Use intelligent search service for better results
        intelligent_search = IntelligentSearchService.new
        context = intelligent_search.search_with_ai_optimization(message, 15)
        search_term = extract_product_keywords(message)
        
        # Get enhanced AI response
        ai_response = intelligent_search.generate_contextual_response(message, context)
        search_metadata[:method] = 'ai_optimized'
      else
        # Use original search method
        search_term = product_query.present? ? product_query : extract_product_keywords(message)
        
        if search_term.present?
          Rails.logger.info "Searching for products with term: #{search_term}"
          
          digikala_service = DigikalaScrapingService.new
          context = digikala_service.search_products(search_term, 15)
          
          Rails.logger.info "Found #{context&.length || 0} products"
        end
        
        # Get standard AI response
        openrouter_service = OpenrouterService.new
        ai_response = openrouter_service.chat_completion(message, context)
        search_metadata[:method] = 'standard'
      end
    else
      # Non-product related query - use standard AI service
      openrouter_service = OpenrouterService.new
      ai_response = openrouter_service.chat_completion(message, nil)
      search_metadata[:method] = 'conversational'
    end

    Rails.logger.info "Generated AI response of length: #{ai_response&.length || 0}"

    # Enhanced response with metadata
    render json: {
      response: ai_response,
      products: context || [],
      searched_for: search_term,
      product_count: context&.length || 0,
      search_metadata: search_metadata.merge({
        query_analysis: analyze_query_metadata(message),
        response_timestamp: Time.current.iso8601
      })
    }
  rescue => e
    Rails.logger.error "Chatbot error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    render json: { 
      error: "Sorry, I encountered an error. Please try again.",
      response: generate_error_fallback_response(message),
      search_metadata: {
        method: 'error_fallback',
        error_type: e.class.name,
        timestamp: Time.current.iso8601
      }
    }, status: :internal_server_error
  end

  private

  def analyze_query_metadata(message)
    {
      language: detect_primary_language(message),
      length: message.length,
      word_count: message.split.length,
      contains_brands: detect_brand_mentions(message),
      contains_price_terms: detect_price_terms(message),
      intent_confidence: calculate_intent_confidence(message),
      category_predictions: predict_categories(message)
    }
  end

  def detect_primary_language(text)
    persian_chars = text.scan(/[\u0600-\u06FF]/).length
    english_chars = text.scan(/[a-zA-Z]/).length
    total_chars = persian_chars + english_chars
    
    return 'unknown' if total_chars == 0
    
    persian_ratio = persian_chars.to_f / total_chars
    if persian_ratio > 0.6
      'persian'
    elsif persian_ratio < 0.2
      'english'
    else
      'mixed'
    end
  end

  def detect_brand_mentions(message)
    brands = [
      'سامسونگ', 'samsung', 'آیفون', 'iphone', 'اپل', 'apple', 'هواوی', 'huawei',
      'شیائومی', 'xiaomi', 'ال جی', 'lg', 'سونی', 'sony', 'ایسوس', 'asus'
    ]
    
    found_brands = brands.select { |brand| message.downcase.include?(brand) }
    found_brands.any? ? found_brands : false
  end

  def detect_price_terms(message)
    price_terms = ['قیمت', 'price', 'تومان', 'ارزان', 'cheap', 'گران', 'expensive', 'بودجه', 'budget']
    price_terms.any? { |term| message.downcase.include?(term) }
  end

  def calculate_intent_confidence(message)
    # Simple confidence calculation based on keyword density
    product_indicators = should_search_products?(message) ? 1 : 0
    specific_terms = extract_product_keywords(message).present? ? 1 : 0
    brand_mentions = detect_brand_mentions(message) ? 1 : 0
    
    confidence = (product_indicators + specific_terms + brand_mentions) / 3.0
    (confidence * 100).round(1)
  end

  def predict_categories(message)
    categories = []
    
    category_patterns = {
      'electronics' => /گوشی|لپ تاپ|تلویزیون|هدفون|phone|laptop|tv|headphone/,
      'home_appliances' => /یخچال|ماشین لباسشویی|مایکروویو|fridge|washing|microwave/,
      'personal_care' => /ماشین اصلاح|شامپو|عطر|shaver|perfume|cosmetic/,
      'fashion' => /لباس|کفش|کیف|clothes|shoes|bag/
    }
    
    category_patterns.each do |category, pattern|
      categories << category if message.match?(pattern)
    end
    
    categories
  end

  def generate_error_fallback_response(message)
    if message.match?(/گوشی|موبایل|phone/)
      "متأسفانه در حال حاضر مشکلی در جستجوی گوشی‌ها پیش آمده. لطفاً دوباره تلاش کنید."
    elsif message.match?(/لپ تاپ|laptop/)
      "مشکلی در دسترسی به اطلاعات لپ تاپ‌ها وجود دارد. لطفاً کمی صبر کرده و مجدد امتحان کنید."
    else
      "در حال حاضر نمی‌توانم به درخواست شما پاسخ دهم. لطفاً دوباره تلاش کنید."
    end
  end

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
