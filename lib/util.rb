# monkey patch string so we can be lazy about
# trailing slashes in yaml config files
class String
  def add_trailing_slash
    self.reverse[0].eql?('/') ? self : self + '/'
  end
end

# log to logfile and stdout
class MultiIO
  def initialize(*targets)
     @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end
