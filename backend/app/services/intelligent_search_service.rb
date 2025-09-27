class IntelligentSearchService
  # Enhances search capabilities with AI-powered query optimization
  
  def initialize
    @digikala_service = DigikalaScrapingService.new
    @openrouter_service = OpenrouterService.new
    @prompt_service = EnhancedPromptService
  end
  
  def search_with_ai_optimization(user_query, limit = 10)
    Rails.logger.info "Starting AI-optimized search for: #{user_query}"
    
    # Step 1: Generate optimized search terms using AI
    optimized_queries = generate_optimized_search_queries(user_query)
    
    # Step 2: Execute searches with different strategies
    all_products = []
    
    optimized_queries.each_with_index do |search_term, index|
      Rails.logger.info "Searching with term #{index + 1}: #{search_term}"
      
      products = @digikala_service.search_products(search_term, limit)
      
      # Tag products with search strategy for analysis
      products.each { |p| p[:search_strategy] = "optimized_#{index + 1}" }
      
      all_products.concat(products)
      
      # Break if we have enough products
      break if all_products.length >= limit
    end
    
    # Step 3: Deduplicate and rank products
    unique_products = deduplicate_products(all_products)
    ranked_products = rank_products_by_relevance(unique_products, user_query)
    
    # Step 4: Return top results
    final_products = ranked_products.take(limit)
    
    Rails.logger.info "AI-optimized search returned #{final_products.length} products"
    final_products
  end
  
  def generate_contextual_response(user_query, products)
    # Use enhanced prompt service for better AI responses
    enhanced_prompt = @prompt_service.generate_product_recommendation_prompt(
      user_query, 
      products,
      extract_user_context(user_query)
    )
    
    # Generate response with enhanced context
    @openrouter_service.chat_completion(user_query, products, enhanced_prompt)
  end
  
  private
  
  def generate_optimized_search_queries(user_query)
    # Try to use AI for query optimization first
    if api_key_available?
      ai_optimized_queries = generate_ai_optimized_queries(user_query)
      return ai_optimized_queries if ai_optimized_queries.any?
    end
    
    # Fallback to rule-based optimization
    generate_rule_based_queries(user_query)
  end
  
  def generate_ai_optimized_queries(user_query)
    prompt = @prompt_service.generate_search_optimization_prompt(user_query)
    
    begin
      response = @openrouter_service.send(:custom_completion, prompt)
      parsed_response = JSON.parse(response)
      
      [
        parsed_response['primary'],
        parsed_response['alternative'], 
        parsed_response['fallback']
      ].compact
    rescue => e
      Rails.logger.error "AI query optimization failed: #{e.message}"
      []
    end
  end
  
  def generate_rule_based_queries(user_query)
    queries = []
    
    # Extract key components
    brands = extract_brands(user_query)
    categories = extract_categories(user_query)
    
    # Generate primary query (most specific)
    if brands.any? && categories.any?
      queries << "#{categories.first} #{brands.first}"
    elsif categories.any?
      queries << categories.first
    elsif brands.any?
      queries << brands.first
    end
    
    # Generate alternative query (broader)
    if categories.any?
      queries << categories.first
    end
    
    # Generate fallback query (generic)
    fallback_terms = extract_meaningful_words(user_query)
    queries << fallback_terms.join(' ') if fallback_terms.any?
    
    # Remove duplicates and empty queries
    queries.compact.uniq.reject(&:blank?)
  end
  
  def extract_brands(query)
    persian_brands = [
      'سامسونگ', 'آیفون', 'اپل', 'هواوی', 'شیائومی', 'ال جی', 'سونی', 'نوکیا',
      'ایسوس', 'لنوو', 'دل', 'اچ پی', 'ام اس آی', 'ایسر', 'فیلیپس', 'پاناسونیک'
    ]
    
    english_brands = [
      'samsung', 'apple', 'iphone', 'huawei', 'xiaomi', 'lg', 'sony', 'nokia',
      'asus', 'lenovo', 'dell', 'hp', 'msi', 'acer', 'philips', 'panasonic'
    ]
    
    found_brands = []
    (persian_brands + english_brands).each do |brand|
      found_brands << brand if query.downcase.include?(brand)
    end
    
    found_brands
  end
  
  def extract_categories(query)
    persian_categories = {
      'گوشی موبایل' => ['گوشی', 'موبایل', 'phone', 'smartphone'],
      'لپ تاپ' => ['لپ تاپ', 'لپتاپ', 'laptop', 'notebook'],
      'هدفون' => ['هدفون', 'هندزفری', 'headphone', 'earphone'],
      'تلویزیون' => ['تلویزیون', 'تی وی', 'tv', 'television'],
      'تبلت' => ['تبلت', 'tablet', 'ipad'],
      'ساعت هوشمند' => ['ساعت هوشمند', 'smartwatch', 'watch'],
      'ماشین اصلاح' => ['ماشین اصلاح', 'اصلاح', 'shaver', 'trimmer']
    }
    
    found_categories = []
    persian_categories.each do |category, keywords|
      if keywords.any? { |keyword| query.downcase.include?(keyword) }
        found_categories << category
      end
    end
    
    found_categories
  end
  
  def extract_features(query)
    feature_keywords = {
      'gaming' => ['گیمینگ', 'gaming', 'بازی', 'game'],
      'camera' => ['دوربین', 'عکاسی', 'camera', 'photo'],
      'battery' => ['باتری', 'battery', 'شارژ', 'charge'],
      'storage' => ['حافظه', 'storage', 'memory', 'گیگ'],
      'processor' => ['پردازنده', 'processor', 'cpu', 'chip']
    }
    
    found_features = []
    feature_keywords.each do |feature, keywords|
      if keywords.any? { |keyword| query.downcase.include?(keyword) }
        found_features << feature
      end
    end
    
    found_features
  end
  
  def extract_meaningful_words(query)
    stopwords = [
      'و', 'یا', 'که', 'را', 'در', 'با', 'از', 'به', 'تا', 'برای', 'خوب',
      'بهترین', 'پیشنهاد', 'بده', 'کن', 'میخوام', 'میخواهم', 'لطفا',
      'the', 'a', 'an', 'and', 'or', 'but', 'for', 'with', 'good', 'best'
    ]
    
    words = query.split(/\s+/)
    meaningful_words = words.select do |word|
      word.length > 2 && !stopwords.include?(word.downcase)
    end
    
    meaningful_words.take(3) # Limit to top 3 words
  end
  
  def deduplicate_products(products)
    # Remove duplicates based on name similarity and URL
    seen_urls = Set.new
    seen_names = Set.new
    unique_products = []
    
    products.each do |product|
      # Skip if we've seen this URL
      next if product[:url] && seen_urls.include?(product[:url])
      
      # Skip if we've seen a very similar name
      normalized_name = normalize_product_name(product[:name])
      next if seen_names.any? { |name| similar_names?(name, normalized_name) }
      
      # Add to results
      unique_products << product
      seen_urls.add(product[:url]) if product[:url]
      seen_names.add(normalized_name)
    end
    
    unique_products
  end
  
  def normalize_product_name(name)
    return "" if name.blank?
    
    # Remove common noise words and normalize spacing
    name.downcase
        .gsub(/\s+/, ' ')
        .gsub(/[^\u0600-\u06FF\u0660-\u0669\u06F0-\u06F9a-zA-Z0-9\s]/, '')
        .strip
  end
  
  def similar_names?(name1, name2)
    # Simple similarity check - could be improved with Levenshtein distance
    return false if name1.blank? || name2.blank?
    
    # Check if one name is contained in the other (accounting for word order)
    words1 = name1.split
    words2 = name2.split
    
    # If names are very short, require exact match
    return name1 == name2 if [words1, words2].any? { |w| w.length <= 2 }
    
    # Check overlap
    common_words = words1 & words2
    similarity = common_words.length.to_f / [words1.length, words2.length].max
    
    similarity > 0.7 # 70% word overlap threshold
  end
  
  def rank_products_by_relevance(products, user_query)
    return products if products.empty?
    
    # Score each product based on relevance factors
    scored_products = products.map do |product|
      score = calculate_relevance_score(product, user_query)
      product.merge(relevance_score: score)
    end
    
    # Sort by relevance score (descending)
    scored_products.sort_by { |p| -p[:relevance_score] }
  end
  
  def calculate_relevance_score(product, user_query)
    score = 0.0
    query_words = user_query.downcase.split
    product_name = product[:name].to_s.downcase
    
    # Name relevance (highest weight)
    query_words.each do |word|
      score += 10 if product_name.include?(word)
    end
    
    # Brand match
    brands = extract_brands(user_query)
    if brands.any? { |brand| product_name.include?(brand.downcase) }
      score += 20
    end
    
    # Price availability bonus
    score += 5 if product[:price] && !product[:price].include?('موجود نیست')
    
    # Rating bonus
    if product[:rating] && product[:rating] != 'بدون امتیاز'
      rating_match = product[:rating].match(/(\d+\.?\d*)/)
      if rating_match
        rating_value = rating_match[1].to_f
        score += rating_value * 2 # 2 points per rating point
      end
    end
    
    # Search strategy bonus (prefer results from more specific searches)
    case product[:search_strategy]
    when 'optimized_1'
      score += 15 # Primary search gets highest bonus
    when 'optimized_2'
      score += 10 # Alternative search gets medium bonus
    when 'optimized_3'
      score += 5  # Fallback search gets small bonus
    end
    
    score
  end
  
  def extract_user_context(query)
    {
      language: detect_language(query),
      intent: analyze_intent(query),
      urgency: analyze_urgency(query),
      technical_level: assess_technical_level(query),
      budget_preference: extract_budget_preference(query),
      usage_context: extract_usage_context(query)
    }
  end
  
  def detect_language(text)
    persian_chars = text.scan(/[\u0600-\u06FF]/).length
    english_chars = text.scan(/[a-zA-Z]/).length
    persian_chars > english_chars ? 'persian' : 'english'
  end
  
  def analyze_intent(query)
    intent_patterns = {
      comparison: /مقایسه|compare|بهتر|vs/,
      recommendation: /پیشنهاد|recommend|بهترین|best/,
      specific_search: /\b(سامسونگ|آیفون|samsung|iphone)\b/,
      budget_search: /ارزان|cheap|قیمت|budget/
    }
    
    detected_intents = []
    intent_patterns.each do |intent, pattern|
      detected_intents << intent if query.match?(pattern)
    end
    
    detected_intents.first || :general_search
  end
  
  def analyze_urgency(query)
    urgent_patterns = /فوری|urgent|امروز|today|سریع|quick/
    query.match?(urgent_patterns) ? 'high' : 'normal'
  end
  
  def assess_technical_level(query)
    technical_patterns = /مشخصات|specs|processor|ram|gpu|benchmark/
    query.match?(technical_patterns) ? 'technical' : 'general'
  end
  
  def extract_budget_preference(query)
    if query.match?(/ارزان|cheap|budget|کم/)
      'budget'
    elsif query.match?(/گران|expensive|premium|پریمیم/)
      'premium'
    else
      'flexible'
    end
  end
  
  def extract_usage_context(query)
    context_patterns = {
      gaming: /گیمینگ|gaming|بازی/,
      work: /کار|work|اداری|office/,
      photography: /عکس|photo|عکاسی/,
      student: /درس|study|دانشجو/
    }
    
    context_patterns.each do |context, pattern|
      return context if query.match?(pattern)
    end
    
    :general
  end
  
  def api_key_available?
    (Rails.application.credentials.dig(:openrouter_api_key) || ENV['OPENROUTER_API_KEY']).present?
  end
end