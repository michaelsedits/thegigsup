Rails.application.routes.draw do
  resources :user_sessions
  resources :users

  get 'login' => 'user_sessions#new', :as => :login
  post 'logout' => 'user_sessions#destroy', :as => :logout

  resources :users
  resources :reposts
  resources :bands
  get 'bands/:id/:month/:year' => 'bands#show'
  resources :venues
  get 'venues/:id/:month/:year' => 'venues#show'
  resources :events do
      get :autocomplete_venue_name, :on => :collection
      get :autocomplete_band_name, :on => :collection
  end
  get 'calendar' => 'events#index'
  get 'calendar/:month/:year' => 'events#index'
  get 'events/:month/:year' => 'events#index', :as => 'month'
  root 'events#index'
  get 'tags/:tag' => 'events#tags'
  get 'tags/:tag/:month/:year' => 'events#tags'
  get 'events/new/venues/:id' => 'events#venew'
  get 'gigs' => 'events#gigs'
end
