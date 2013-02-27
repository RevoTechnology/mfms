# Mfms

Library to communicate with 

## Installation

Add this line to your application's Gemfile:

    gem 'mfms', :git => 'git@github.com:RevoTechnology/mfms.git' # TODO: push to rubygems

And then execute:

    $ bundle

Or install it yourself as:

    $ TODO

## Usage

  Mfms::SMS.settings = {
    :login      => 'login',
    :password   => 'password',
    :server     => 'server',
    :port       => port,
    :ssl_port   => ssl_port,
    :cert       => 'path/to/cert',
  }

  sms = Mfms::SMS.new('phone','title','text') # initialize sms
  sms.send # send sms
  sms.id # get sms id
  sms.code # get sms id

Ex.:

  sms = Mfms::SMS.new('79031111111','MyFavouriteCompany','Testing mfms gem')

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
