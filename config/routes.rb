Rails.application.routes.draw do
  get 'home/about', to: 'home#about', as: :about
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get 'upload_files_page', to: 'items#upload_files_page', as: :upload_files_page
  post 'upload_files', to: 'items#upload_files', as: :upload_files
  resources :items do
  end
  resources :tags
  resource :registration, only: [:new, :create]
  resource :session
  resources :passwords, param: :token
  resources :admin_users, except: [:show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'home#about'

  get '/change_locale/:locale', to: 'settings#change_locale', as: :change_locale
end
