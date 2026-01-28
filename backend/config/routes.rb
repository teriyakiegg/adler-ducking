Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Auth
      post "auth/google", to: "auth#google"
      get "auth/me", to: "auth#me"

      resources :conversations, only: [ :index, :show, :create ] do
        resources :messages, only: [ :create ]
        post :chat, to: "chat#create"
      end
      resource :adler_schema, only: [ :show, :update ]
      resources :schema_mappings, only: [ :update ] do
        member do
          post :confirm
          post :reject
        end
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
