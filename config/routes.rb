Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  scope "(:locale)", locale: /#{I18n.available_locales.join('|')}/ do
    get 'home/about', to: 'home#about', as: :about
    get 'upload_files_page', to: 'items#upload_files_page', as: :upload_files_page
    post 'upload_files', to: 'items#upload_files', as: :upload_files
    resources :items
    resources :tags
    resource :registration, only: [:new, :create]
    resource :session
    resources :passwords, param: :token
    resources :admin_users, except: [:show]

    # Defines the root path route ("/")
    root 'home#about'
  end

end
