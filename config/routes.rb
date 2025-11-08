Rails.application.routes.draw do
  devise_for :users

  # Authenticated users land on Work Orders
  authenticated :user do
    root "work_orders#index", as: :authenticated_root
  end

  # Unauthenticated root – Devise sign-in
  devise_scope :user do
    unauthenticated do
      root "devise/sessions#new"
    end
  end

  # Admin user management
  # Admin user management under /admin/users
    # Admin user management under /admin/users with helper prefix "admin_"
  # scope :admin, as: :admin do
  #   resources :users,
  #             controller: "users",
  #             only: [:index, :show, :new, :create]
  # end
  namespace :admin do
    resources :users
  end

  resources :work_orders do
    resources :purchase_orders, only: [:new, :create, :index]
  end

  resources :purchase_orders, only: [:index, :show]


  # Core CRM resources
  resources :customers
  resources :work_orders do
    member do
      patch :complete
      get   :invoice
    end

    resources :work_order_calls, only: [:show, :new, :create]

    resources :time_entries do
      collection do
        get :batch_new
        post :batch_create
      end
    end
  end
  resources :time_entries
  resources :purchase_orders, except: [:new, :create]
  resources :quotes
  resources :preventative_maintenance_contracts
  resources :customer_form_templates
  resource :ojt, only: [:show, :update], controller: "ojt" do
    post :sync_current_month
  end


  get "/search", to: "search#index", as: :search
  get "/tech_reference", to: "tech_reference#index", as: :tech_reference
  resources :messages, only: [:create]

  get "up" => "rails/health#show", as: :rails_health_check
end
