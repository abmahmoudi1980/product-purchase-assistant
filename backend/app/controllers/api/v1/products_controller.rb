class Api::V1::ProductsController < ApplicationController
  def search
    query = params[:q] || params[:query]
    limit = (params[:limit] || 30).to_i

    if query.blank?
      render json: { error: "Search query cannot be blank" }, status: :bad_request
      return
    end

    digikala_service = DigikalaScrapingService.new
    products = digikala_service.search_products(query, limit)

    render json: {
      query: query,
      products: products,
      count: products.length
    }
  rescue => e
    Rails.logger.error "Product search error: #{e.message}"
    render json: { 
      error: "Sorry, I couldn't search for products right now. Please try again later."
    }, status: :internal_server_error
  end
end
