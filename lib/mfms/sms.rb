# encoding: UTF-8
require 'net/http'
require 'openssl'
require 'uri'

module Mfms
  class SMS

    attr_accessor :phone, :subject, :message
    attr_reader :code, :id

    def initialize(phone, subject, message, ssl=true)
      @port = ssl ? @@ssl_port : @@port
      @ssl = ssl
      @phone = phone
      @subject = subject
      @message = message

      validate!
    end

    def self.settings=(settings={})
      @@login = settings[:login]
      @@password = settings[:password]
      @@server = settings[:server]
      @@port = settings[:port]
      @@ssl_port = settings[:ssl_port]
      @@cert_store = OpenSSL::X509::Store.new
      @@cert_store.add_cert OpenSSL::X509::Certificate.new File.read(settings[:cert])

      validate_settings!
    end

    def ssl=(flag)
      @port = flag ? @@ssl_port : @@port
      @ssl = flag
    end

    def send
      return stubbed_send if (defined?(Rails) && !Rails.env.production?)

      establish_connection(@ssl).start do |http|
        request = Net::HTTP::Get.new(send_url)
        response = http.request(request)
        splitted_body = response.body.split(';')
        @code = splitted_body[0]
        @id = splitted_body[2]
        # result = case res_code
        #   when "ok" then "сообщения приняты на отправку"
        #   when "error-system" then "при обработке данного сообщения произошла системная ошибка"
        #   when "error-address-format" then "ошибка формата адреса"
        #   when "error-address-unknown" then "отправка по данному направлению не разрешена"
        #   when "error-subject-format" then "ошибка формата отправителя"
        #   when "error-subject-unknown" then "данный отправителть не разрешен на нашей платформе"
        # end
      end
    end

    # Not used atm

    # def self.status msg_id
    #   puts "Сообщение присвоен ID:"
    #   puts msg_id

    #   connection = establish_connection(@ssl)
    #   connection.start do |http|
    #     request = Net::HTTP::Get.new(status_url msg_id)
    #     response = http.request(request)
    #     splitted_body = response.body.split(';')
    #     res_code = splitted_body[0]
    #     result = case res_code
    #       when "ok" then "Запрос успешно обработан"
    #       when "error-system" then "Произошла системная ошибка"
    #       when "error-provider-id-unknown" then "Сообщение с таким идентификатором не найдено"
    #     end
    #     stat_code = splitted_body[2]
    #     unless stat_code.nil?
    #       @status = case stat_code
    #         when "enqueued" then "сообщение находится в очереди на отправку"
    #         when "sent" then "сообщение отправлено"
    #         when "delivered" then "сообщение доставлено до абонента"
    #         when "undelivered" then "сообщение недоставлено до абонента"
    #         when "failed" then "сообщение недоставлено из-за ошибки на платформе"
    #         when "delayed" then "было указано отложенное время отправки и сообщение ожидает его"
    #         when "cancelled" then "сообщение было отменено вручную на нашей платформе"
    #       end
    #     end
    #   end

    #   if @status
    #     @status
    #   else
    #     "ошибка"
    #   end
    # end 

    # What for?
    # def to_json
    #   {:url => "#{server}:#{port}#{url}", :sms_message => message}.to_json
    # end

  private

    def stubbed_send
    end

    def establish_connection(ssl=true)
      http = Net::HTTP.new(@@server, @port)
      if ssl
        http.cert_store = @@cert_store
        http.use_ssl = true
      end
      http
    end

    def validate! 
    end

    def self.validate_settings!
    end

    def send_url
      "/revoup/connector0/send?login=#{@@login}&password=#{@@password}&" +
      "subject[0]=#{@subject}&address[0]=#{@phone}&text[0]=#{URI.encode(@message)}"
    end

    # Not used atm

    # def status_url msg_id
    #   "/revoup/connector0/status?login=#{@@login}&password=#{@@password}&" +
    #   "providerId[0]=#{msg_id}"
    # end

  end
end
