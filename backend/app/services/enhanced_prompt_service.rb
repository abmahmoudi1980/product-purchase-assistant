class EnhancedPromptService
  # Enhanced AI prompt generation for better product search and recommendations
  
  def self.generate_search_optimization_prompt(user_query, context = {})
    <<~PROMPT
      You are an expert product search analyst for Digikala.com. Your task is to optimize search queries for better product discovery.
      
      Original user query: "#{user_query}"
      
      Context:
      - Language: #{detect_language(user_query)}
      - Intent: #{analyze_intent(user_query)}
      - Budget indicators: #{extract_budget_indicators(user_query)}
      - Category hints: #{extract_category_hints(user_query)}
      
      Generate 3 optimized search terms for Digikala that would return the most relevant products:
      1. Primary search term (most specific)
      2. Alternative search term (broader category)
      3. Fallback search term (generic but relevant)
      
      Consider:
      - Persian vs English keywords
      - Brand synonyms and variations
      - Category-specific terminology
      - Price range indicators
      - Feature requirements mentioned
      
      Return in JSON format:
      {
        "primary": "optimized_term_1",
        "alternative": "optimized_term_2", 
        "fallback": "optimized_term_3",
        "reasoning": "explanation of optimization strategy"
      }
    PROMPT
  end
  
  def self.generate_product_recommendation_prompt(user_query, products, user_context = {})
    base_prompt = build_persona_prompt
    context_prompt = build_context_prompt(user_query, user_context)
    products_prompt = build_products_prompt(products)
    instruction_prompt = build_instruction_prompt
    
    "#{base_prompt}\n\n#{context_prompt}\n\n#{products_prompt}\n\n#{instruction_prompt}"
  end
  
  private
  
  def self.build_persona_prompt
    <<~PROMPT
      You are a highly knowledgeable Persian-speaking product consultant specializing in Digikala.com products.
      Your expertise includes:
      - Deep knowledge of Iranian consumer preferences and market trends
      - Understanding of Persian product terminology and brand names
      - Awareness of local pricing patterns and value propositions
      - Cultural sensitivity to Persian shopping habits and expectations
      
      Your communication style:
      - Warm, helpful, and professional in Persian
      - Use appropriate formal/informal register based on query tone
      - Include cultural references where relevant
      - Explain technical terms in accessible Persian
    PROMPT
  end
  
  def self.build_context_prompt(user_query, user_context)
    <<~PROMPT
      User Query Analysis:
      - Original message: "#{user_query}"
      - Language: #{detect_language(user_query)}
      - Intent: #{analyze_intent(user_query)}
      - Urgency level: #{analyze_urgency(user_query)}
      - Technical expertise: #{assess_technical_level(user_query)}
      - Budget sensitivity: #{extract_budget_indicators(user_query)}
      - Usage context: #{extract_usage_context(user_query)}
    PROMPT
  end
  
  def self.build_products_prompt(products)
    return "No products found for this query." if products.empty?
    
    prompt = "Available Products from Digikala:\n"
    products.each_with_index do |product, index|
      prompt += <<~PRODUCT
        
        Product #{index + 1}:
        - Name: #{product[:name]}
        - Price: #{product[:price]}
        - Rating: #{product[:rating]} 
        - Brand: #{product[:brand]}
        - Description: #{product[:description]}
        - URL: #{product[:url]}
        - Value Analysis: #{analyze_product_value(product)}
        - Target User: #{identify_target_user(product)}
        
      PRODUCT
    end
    prompt
  end
  
  def self.build_instruction_prompt
    <<~PROMPT
      Instructions:
      1. Analyze all provided products comprehensively
      2. Compare based on: price/value ratio, brand reputation, user ratings, features
      3. Provide clear recommendations for different use cases
      4. Highlight pros and cons for each significant option
      5. Ask follow-up questions to better understand specific needs
      6. Include cultural context (e.g., popular brands in Iran, local preferences)
      7. Mention any seasonal considerations or current market trends
      8. Provide actionable advice for making the final decision
      
      Response format:
      - Start with a brief acknowledgment of their request
      - Provide product analysis and recommendations
      - Include comparison table if multiple viable options
      - End with specific next steps or questions
      
      Always respond in fluent, natural Persian with appropriate technical vocabulary.
    PROMPT
  end
  
  def self.detect_language(text)
    # Simple language detection
    persian_chars = text.scan(/[\u0600-\u06FF]/).length
    english_chars = text.scan(/[a-zA-Z]/).length
    
    if persian_chars > english_chars
      "Persian (Primary) with some English terms"
    elsif english_chars > persian_chars
      "English (Primary) with some Persian terms"
    else
      "Mixed Persian/English"
    end
  end
  
  def self.analyze_intent(query)
    intents = {
      comparison: /مقایسه|compare|بهتر|better|vs|در مقابل/,
      budget: /ارزان|cheap|قیمت|price|budget|تومان/,
      specific_feature: /عکاس|camera|gaming|گیمینگ|باتری|battery/,
      urgent: /فوری|urgent|زود|سریع|امروز|today/,
      recommendation: /پیشنهاد|recommend|بهترین|best|چی|what|کدام/,
      replacement: /جایگزین|replace|alternative|بجای/
    }
    
    detected = []
    intents.each do |intent, pattern|
      detected << intent if query.match?(pattern)
    end
    
    detected.join(", ") || "general_inquiry"
  end
  
  def self.analyze_urgency(query)
    urgent_indicators = /فوری|urgent|امروز|today|سریع|quick|زود|soon/
    query.match?(urgent_indicators) ? "high" : "normal"
  end
  
  def self.assess_technical_level(query)
    technical_terms = /specs|مشخصات|processor|پردازنده|ram|حافظه|gpu|benchmark/
    query.match?(technical_terms) ? "technical" : "general"
  end
  
  def self.extract_budget_indicators(query)
    if query.match?(/ارزان|cheap|کم|budget/)
      "budget_conscious"
    elsif query.match?(/گران|expensive|premium|پریمیم/)
      "premium_seeker"
    elsif query.match?(/متوسط|middle|میان/)
      "mid_range"
    else
      "flexible"
    end
  end
  
  def self.extract_usage_context(query)
    contexts = {
      gaming: /gaming|گیمینگ|بازی|game/,
      work: /کار|work|office|اداری|business/,
      study: /درس|study|دانشجو|student|university/,
      photography: /عکس|photo|camera|عکاسی/,
      daily_use: /روزانه|daily|عادی|normal/
    }
    
    detected = []
    contexts.each do |context, pattern|
      detected << context if query.match?(pattern)
    end
    
    detected.join(", ") || "general_use"
  end
  
  def self.extract_category_hints(query)
    categories = {
      electronics: /گوشی|لپ تاپ|تلویزیون|هدفون/,
      home_appliance: /یخچال|ماشین لباسشویی|مایکروویو/,
      personal_care: /ماشین اصلاح|شامپو|عطر/,
      fashion: /لباس|کفش|کیف/
    }
    
    categories.map { |category, pattern| category if query.match?(pattern) }.compact
  end
  
  def self.analyze_product_value(product)
    # Simple value analysis based on available data
    price_str = product[:price].to_s
    rating_str = product[:rating].to_s
    
    if price_str.include?('ارزان') || price_str.include?('تخفیف')
      "Good value - discounted price"
    elsif rating_str.match?(/[4-5]/)
      "High rated - quality option"
    else
      "Standard option"
    end
  end
  
  def self.identify_target_user(product)
    name = product[:name].to_s.downcase
    
    if name.match?(/gaming|گیمینگ/)
      "Gamers and power users"
    elsif name.match?(/business|اداری/)
      "Professional and office use"
    elsif name.match?(/budget|ارزان/)
      "Budget-conscious buyers"
    else
      "General consumers"
    end
  end
end