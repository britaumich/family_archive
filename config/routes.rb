Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  scope "(:locale)", locale: /#{I18n.available_locales.join('|')}/ do
    get 'home/about', to: 'home#about', as: :about
    get 'upload_files_page', to: 'items#upload_files_page', as: :upload_files_page
    post 'upload_files', to: 'items#upload_files', as: :upload_files
    resources :items do
      get :editing_tags_page, on: :collection
      patch :bulk_assign_tags, on: :collection
      patch :bulk_remove_tags, on: :collection
      patch :assign_tags, on: :member
      patch :remove_tags, on: :member
    end
    resources :tags do
      patch :bulk_assign, on: :collection
    end
    resources :tag_types
    resource :registration, only: [:new, :create]
    resource :session
    resources :passwords, param: :token
    resources :admin_users, except: [:show]

    # Defines the root path route ("/")
    root 'home#about'
  end
end
