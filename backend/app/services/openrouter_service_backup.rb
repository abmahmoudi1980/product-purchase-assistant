class OpenrouterService
  include HTTParty
  base_uri 'https://openrouter.ai/api/v1'

  def initialize
    @headers = {
      'Authorization' => "Bearer #{Rails.application.credentials.openrouter_api_key || ENV['OPENROUTER_API_KEY']}",
      'Content-Type' => 'application/json'
    }
  end

  def chat_completion(message, context = nil, custom_prompt = nil)
    api_key = Rails.application.credentials.dig(:openrouter_api_key) || ENV['OPENROUTER_API_KEY']
    
    # If no API key is available, return a helpful fallback response
    unless api_key.present?
      return generate_fallback_response(message, context)
    end

    # Use custom prompt if provided, otherwise build standard system prompt
    system_prompt = custom_prompt || build_system_prompt(context)
    
    body = {
      model: "deepseek/deepseek-chat-v3.1:free",
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user", 
          content: message
        }
      ],
      max_tokens: 1500, # Increased for more detailed responses
      temperature: 0.7,
      top_p: 0.9,
      frequency_penalty: 0.1 # Reduce repetition
    }

    @headers['Authorization'] = "Bearer #{api_key}"

    response = self.class.post('/chat/completions', {
      body: body.to_json,
      headers: @headers,
      timeout: 30 # 30 second timeout
    })

    if response.success?
      content = response.parsed_response.dig("choices", 0, "message", "content")
      Rails.logger.info "OpenRouter API successful response length: #{content&.length || 0}"
      content
    else
      Rails.logger.error "OpenRouter API error: #{response.code} - #{response.body}"
      generate_fallback_response(message, context)
    end
  rescue Net::TimeoutError => e
    Rails.logger.error "OpenRouter API timeout: #{e.message}"
    generate_fallback_response(message, context, "timeout")
  rescue => e
    Rails.logger.error "OpenRouter Service error: #{e.message}"
    generate_fallback_response(message, context, "error")
  end

  def custom_completion(prompt, options = {})
    # Method for direct prompt completion (used by intelligent search)
    api_key = Rails.application.credentials.dig(:openrouter_api_key) || ENV['OPENROUTER_API_KEY']
    
    return nil unless api_key.present?

    body = {
      model: options[:model] || "deepseek/deepseek-chat-v3.1:free",
      messages: [
        {
          role: "user",
          content: prompt
        }
      ],
      max_tokens: options[:max_tokens] || 500,
      temperature: options[:temperature] || 0.3 # Lower temperature for more structured responses
    }

    @headers['Authorization'] = "Bearer #{api_key}"

    response = self.class.post('/chat/completions', {
      body: body.to_json,
      headers: @headers,
      timeout: 20
    })

    if response.success?
      response.parsed_response.dig("choices", 0, "message", "content")
    else
      Rails.logger.error "OpenRouter custom completion error: #{response.body}"
      nil
    end
  rescue => e
    Rails.logger.error "OpenRouter custom completion error: #{e.message}"
    nil
  end
  rescue => e
    Rails.logger.error "OpenRouter Service error: #{e.message}"
    generate_fallback_response(message, context)
  end

  private

  def generate_fallback_response(message, context, error_type = nil)
    # Generate a helpful response without AI when API key is not available
    if context&.any?
      product_names = context.map { |p| p[:name] }.join("، ")
      product_count = context.length
      
      # Create more sophisticated fallback based on error type
      response_prefix = case error_type
      when "timeout"
        "پاسخ کامل هوش مصنوعی به دلیل کندی شبکه دریافت نشد، اما"
      when "error"  
        "خدمات هوش مصنوعی موقتاً در دسترس نیست، ولی"
      else
        "بر اساس جستجوی شما،"
      end
      
      <<~RESPONSE
        #{response_prefix} #{product_count} محصول مرتبط پیدا کردم: #{product_names}

        درباره درخواست شما "#{message}" می‌توانم این تحلیل کلی را ارائه دهم:

        #{analyze_user_intent(message, context)}

        #{generate_product_summary(context)}

        #{error_type ? "برای دریافت تحلیل کامل هوش مصنوعی، لطفاً دوباره تلاش کنید." : "برای توصیه‌های دقیق‌تر هوش مصنوعی، نیاز به تنظیم کلید API OpenRouter است."}
      RESPONSE
    else
      <<~RESPONSE
        درخواست شما "#{message}" را متوجه شدم.

        من یک دستیار خرید محصولات هستم که به شما کمک می‌کنم بهترین محصولات را از دیجی‌کالا پیدا کنید. 
        #{error_type ? "در حال حاضر خدمات هوش مصنوعی در دسترس نیست، ولی" : "در حالی که"} می‌توانم محصولات را جستجو کنم.

        هنوز هم می‌توانید از من استفاده کنید برای:
        - جستجوی محصولات خاص
        - مقایسه قیمت‌ها و امتیازات  
        - دریافت اطلاعات پایه محصولات

        از من درباره محصولات خاصی مثل "لپ تاپ گیمینگ"، "گوشی سامسونگ" یا "هدفون بی سیم" بپرسید!
      RESPONSE
    end
  end

  def generate_product_summary(products)
    return "" if products.empty?
    
    # Analyze price ranges
    prices_with_values = products.map { |p| extract_price_value(p[:price]) }.compact
    
    if prices_with_values.any?
      min_price = prices_with_values.min
      max_price = prices_with_values.max
      avg_price = (prices_with_values.sum / prices_with_values.length.to_f).round
      
      price_summary = "قیمت‌ها از #{format_price(min_price)} تا #{format_price(max_price)} تومان (میانگین: #{format_price(avg_price)} تومان)"
    else
      price_summary = "اطلاعات قیمت برای بیشتر محصولات در دسترس است"
    end
    
    # Analyze brands
    brands = products.map { |p| p[:brand] }.compact.uniq.reject { |b| b == "نامشخص" }
    brand_summary = brands.any? ? "برندهای موجود: #{brands.join('، ')}" : "برندهای مختلفی موجود است"
    
    # Analyze ratings
    ratings = products.map { |p| extract_rating_value(p[:rating]) }.compact
    rating_summary = if ratings.any?
      avg_rating = (ratings.sum / ratings.length.to_f).round(1)
      "میانگین امتیاز: #{avg_rating} از ۵"
    else
      "امتیازات کاربران قابل مشاهده است"
    end
    
    "\n📊 خلاصه محصولات یافت شده:\n• #{price_summary}\n• #{brand_summary}\n• #{rating_summary}\n"
  end

  def extract_price_value(price_string)
    return nil if price_string.blank? || price_string.include?('موجود نیست')
    
    # Extract numeric value from Persian/English price strings
    numbers = price_string.gsub(/[,،]/, '').scan(/\d+/).join.to_i
    numbers > 0 ? numbers : nil
  end

  def extract_rating_value(rating_string)
    return nil if rating_string.blank? || rating_string.include?('بدون امتیاز')
    
    # Extract numeric rating
    match = rating_string.match(/(\d+\.?\d*)/)
    match ? match[1].to_f : nil
  end

  def format_price(price)
    # Format price with Persian thousand separators
    price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1،').reverse
  end

  def analyze_user_intent(message, context)
    # Simple intent analysis for fallback responses
    case message.downcase
    when /laptop|لپ تاپ/
      "برای لپ تاپ‌ها توصیه می‌کنم این موارد را در نظر بگیرید: نوع پردازنده (Intel در مقابل AMD)، رم (حداقل ۸ گیگابایت برای کار)، حافظه (SSD ترجیحی)، و اندازه صفحه نمایش (۱۳-۱۵ اینچ برای قابلیت حمل)."
    when /phone|گوشی|موبایل/
      "برای گوشی‌های هوشمند، عوامل کلیدی شامل: عمر باتری، کیفیت دوربین، ظرفیت حافظه، و قابلیت اعتماد برند است. بودجه و نحوه استفاده‌تان را در نظر بگیرید."
    when /budget|قیمت|ارزان/
      "بودجه مهم است! به دنبال بهترین ارزش در مقابل قیمت باشید - گاهی محصولات میان‌رده نسبت قیمت به عملکرد بهتری نسبت به محصولات پرچمدار ارائه می‌دهند."
    else
      "عواملی مثل شهرت برند، نظرات کاربران، گارانتی، و نیازهای خاص خود را هنگام تصمیم‌گیری برای خرید در نظر بگیرید."
    end
  end

  def build_system_prompt(context)
    base_prompt = <<~PROMPT
      You are a helpful product purchase assistant specializing in products from Digikala.com. 
      Your role is to help users find the best products based on their needs, comparing prices, 
      features, and providing recommendations.

      When helping users:
      1. Analyze the product information provided and give detailed comparisons
      2. Ask clarifying questions about their specific needs and budget
      3. Highlight pros and cons of different options based on the data
      4. Consider price-to-value ratio and recommend the best options
      5. Mention any notable features, ratings, or brands
      6. Be conversational and helpful
      7. Suggest which product might be best for different use cases

      Always respond in Persian (Farsi) language and in a friendly, informative manner. 
      Use the actual product data to make specific recommendations and comparisons.
    PROMPT

    if context&.any?
      base_prompt += "\n\nHere are the products I found from Digikala search:\n"
      context.each do |product|
        base_prompt += "- نام: #{product[:name]}\n"
        base_prompt += "  قیمت: #{product[:price]}\n"
        base_prompt += "  امتیاز: #{product[:rating]}\n"
        base_prompt += "  برند: #{product[:brand]}\n"
        base_prompt += "  توضیحات: #{product[:description]}\n"
        base_prompt += "  لینک: #{product[:url]}\n\n"
      end
      base_prompt += "\nPlease analyze these products and provide helpful recommendations based on the user's query. Compare prices, features, ratings, and brands to help them make the best choice."
    else
      base_prompt += "\n\nNo specific products were found. Please help the user refine their search or suggest general product categories."
    end

    base_prompt
  end
end