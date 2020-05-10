Amistad::ActiveRecordFriendModel.module_eval  do
    def invite(user)
      return false if user == self || find_any_friendship_with(user)
      Amistad.friendship_class.new{ |f| f.friendable = self ; f.friend = user }.save(validate: false)
    end
end
