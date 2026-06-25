YogaStudio::Application.routes.draw do
  namespace :api do
    namespace :v1 do
      post 'auth/register', to: 'auth#register'
      post 'auth/login', to: 'auth#login'

      resources :courses, only: [:index, :show] do
        post 'book', on: :member
        post 'cancel', on: :member
      end

      resources :bookings, only: [:index, :show]

      resources :notifications, only: [:index] do
        patch 'read', on: :member
      end

      namespace :teacher do
        resources :courses, only: [:index, :show] do
          get 'today', on: :collection
        end
        resources :attendances, only: [:create] do
          post 'batch_check_in', on: :collection
        end
      end
    end
  end
end
