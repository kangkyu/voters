Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :users, only: [:new, :show, :edit, :update, :create, :index]
  get "register" => "users#new"

  resource :session, only: [:new, :create, :destroy]
  resource :language, only: [:update]
  get "signin" => "sessions#new"

  resources :rounds, only: [:show, :new, :create] do
    resources :audiences, only: [:new, :create]
    resources :agenda_items, only: [:index] do
      resources :votes, only: [:create]
    end
  end

  namespace :owner do
    resources :rounds, only: [] do
      resources :audiences, only: [:index, :destroy]
      resource :passcode, only: [:create, :destroy]
      resources :agenda_items, only: [:new, :create, :show, :edit, :update, :destroy, :index]
      get "results" => "agenda_items#result"
      get "minutes" => "agenda_items#minutes"
    end
  end

  namespace :admin do
    get "dashboard" => "dashboard#index"
  end

  # Defines the root path route ("/")
  root "pages#home"
end
