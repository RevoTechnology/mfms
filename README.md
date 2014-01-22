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
    
Define settings:

    Mfms::SMS.settings = {
      :login      => 'login',
      :password   => 'password',
      :server     => 'server',
      :port       => port,
      :ssl_port   => ssl_port,
      :cert       => 'path/to/cert',
      :ssl        => true # default is true
      :translit   => true # default is false
    }

Initialize sms:

    sms = Mfms::SMS.new('phone','title','text') # initialize sms

Send it and get sent sms id and dispatch code:

    sms.send # send sms. returns sms id or dispatch code if something went wrong
    sms.id # get sms id

Get current sms status and update it:

    sms.status # get sms delivery status
    sms.update_status # updates sms delivery status. returns status or status check response code on error

Get any sms status:

    code, status = Mfms::SMS.status(sms_id) # code - response code can contain error description, status - sms delivery status if code is 'ok'

Ex.:

    sms = Mfms::SMS.new('79031111111','MyFavouriteCompany','Testing mfms gem')
    sms.send # => 1032
    sms.id # => 1032

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
