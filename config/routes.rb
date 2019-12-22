Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "/home/info" => "home#info", as: "home_info"

  get "/user/:user/dashboard" => "user#dashboard", as: "user_dashboard"
  get "/user/:user/find_origin" => "user#find_origin", as: "find_origin"

  root 'home#info'



end
