# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :books, only: %i[index show create destroy]
      resources :readers, only: %i[show create]

      resources :borrowings, only: %i[create] do
        post :return, on: :member, action: :return_book
      end
    end
  end
end
