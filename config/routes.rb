Rails.application.routes.draw do
  resources :organizations, only: [:create, :show] do
    post :add_instructor, on: :member
  end
end