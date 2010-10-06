if defined?(Rails)
  Hashish::Data::Apply.blacklist << :controller << :action

  # Hashish.load('rails/controller')
end
