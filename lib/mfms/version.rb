module Mfms
  class Version
    MAJOR = 0
    MINOR = 6
    PATCH = 1

    def self.to_s
      "#{MAJOR}.#{MINOR}.#{PATCH}"
    end
  end
end
