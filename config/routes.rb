Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get "/home/info" => "home#info", as: "home_info"

  get "/user/:user/dashboard" => "user#dashboard", as: "user_dashboard"
  get "/user/:user/find_origin" => "user#find_origin", as: "find_origin"

  get "user/:user/upload_file/new" => "uploadedfile#new", as: "new_upload_file"
  post "user/:user/upload_file" => "uploadedfile#create", as: "create_upload_file"

  root 'home#info'



end
