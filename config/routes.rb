Rails.application.routes.draw do
  mount Notifications::Engine => "/notifications"
  devise_for :users, :controllers => {
      :registrations => 'users/registrations',
      sessions: "users/sessions",
      passwords: "users/passwords",
      confirmations: "users/confirmations"
  }

  get "/home/info" => "home#info", as: "home_info"
  get "home/contact" => "home#contact", as: "contact"
  post "home/contact/submit" => "home#contactSubmit", as: "contact_submit"
  get"home/faq" => "home#faq", as: "faq"

  get "/user/dashboard" => "user#dashboard", as: "user_dashboard"
  get "/user/friends" => "user#friends", as: "friends"
  post "/user/friends/addfriend" => "user#add_friend", as: "add_friend"
  get "/user/friends/acceptfriend/:request_issuer" => "user#accept_friend_request", as: "accept_friend"
  get "user/friends/removefriend/:friend" => "user#remove_friend", as: "remove_friend"

  get "user/upload_file/new" => "uploadedfile#new", as: "new_upload_file"
  post "user/upload_file" => "uploadedfile#create", as: "create_upload_file"
  get "user/show_file/:file_id" => "uploadedfile#show", as: "show_upload_file"
  delete "user/delete_file/:file_id" => "uploadedfile#delete", as: "delete_upload_file"
  get "user/graph_file/:file_id" => "uploadedfile#graph", as: "graph_file"

  post "/user/upload_file/:file_id/find_origin" => "uploadedfile#find_origin", as: "find_origin"
  get "/user/upload_file/:file_id/find_origin/upload" => "uploadedfile#find_origin_form", as: "find_origin_form"
  get "/user/upload_file/:file_id/find_origin/results" => "uploadedfile#find_origin_results", as: "find_origin_results"

  get "user/sharedfile/edit/:file_id" => "sharedfile#edit_share", as: "edit_share_file"
  post "user/sharedfile/:file_id" => "sharedfile#share", as: "share_file"
  get "user/sharedfile/:file_id/remove_share/:user_id" => "sharedfile#remove_user", as: "remove_user_share_file"
  get "user/sharedfile/:file_id/shared_users" => "sharedfile#shared_users", as: "shared_users"

  get "notifications_count" => "application#notifications_count", as: "notifications_count"

  root 'home#info'

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

end
