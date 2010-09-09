if defined?(Rails)
  Hashish::Data::Apply.blacklist << :controller << :action
end
