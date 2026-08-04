Rails.application.routes.draw do
  root "dashboard#show"

  resources :audits, only: %i[create show]
  resources :findings, only: :update
  resource :settings, only: %i[edit update]
  resources :plans, only: :index
  resource :billing_subscription, only: %i[create destroy] do
    get :callback
  end

  scope module: :public do
    get "privacy", to: "legal#privacy", as: :privacy
    get "terms", to: "legal#terms", as: :terms
    get "support", to: "legal#support", as: :support
  end

  mount ShopifyApp::Engine, at: "/"

  get "up" => "rails/health#show", as: :rails_health_check
end
