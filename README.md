# Mfms

Library to communicate with Mobile Finance Management Solutions

## Installation

Add this line to your application's Gemfile:

    $ gem 'mfms'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mfms

## Usage
    
Define settinfs:

    Mfms::SMS.settings = {
      :login      => 'login',
      :password   => 'password',
      :server     => 'server',
      :port       => port,
      :ssl_port   => ssl_port,
      :cert       => 'path/to/cert',
    }

Initialize sms:

    sms = Mfms::SMS.new('phone','title','text') # initialize sms

Send it and get sent sms id and dispatch code

    sms.send # send sms
    sms.id # get sms id
    sms.code # get sms dispatch code

Ex.:

    sms = Mfms::SMS.new('79031111111','MyFavouriteCompany','Testing mfms gem')
    sms.send
    sms.id # => 1032
    sms.code # => ok

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
