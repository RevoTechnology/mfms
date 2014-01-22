# encoding: UTF-8
require 'net/http'
require 'openssl'
require 'uri'
require 'translit'

module Mfms
  class SMS

    attr_accessor :phone, :subject, :message
    attr_reader :id, :status

    def initialize(phone, subject, message)
      @phone = phone
      @subject = subject
      @message = message
      @status = 'not-sent'

      validate!
    end

    def self.settings=(settings={})
      @@login = settings[:login]
      @@password = settings[:password]
      @@server = settings[:server]
      @@port = settings[:port]
      @@ssl_port = settings[:ssl_port]
      @@cert_store = init_cert_store settings[:cert]
      @@ssl = !settings[:ssl].nil? ? settings[:ssl] : true # connect using ssl by default
      @@translit = !settings[:translit].nil? ? settings[:translit] : false # use translit or not
      validate_settings!
    end

    def self.ssl=(flag)
      @@ssl = flag
    end

    def self.ssl
      @@ssl
    end

    # => SMS send status codes:
    #    "ok"                     "Сообщения приняты на отправку"
    #    "error-system"           "При обработке данного сообщения произошла системная ошибка"
    #    "error-address-format"   "Ошибка формата адреса"
    #    "error-address-unknown"  "Отправка по данному направлению не разрешена"
    #    "error-subject-format"   "Ошибка формата отправителя"
    #    "error-subject-unknown"  "Данный отправителть не разрешен на нашей платформе"

    def send
      #return stubbed_send if (defined?(Rails) && !Rails.env.production?)
      self.class.establish_connection.start do |http|
        request = Net::HTTP::Get.new(send_url)
        response = http.request(request)
        body = response.body.split(';')
        return body[0] unless body[0] == 'ok'
        @status = 'sent'
        @id = body[2]
      end
    end
    
    # => SMS delivery status codes:
    #    "enqueued"     "Сообщение находится в очереди на отправку"
    #    "sent"         "Сообщение отправлено"
    #    "delivered"    "Сообщение доставлено до абонента"
    #    "undelivered"  "Сообщение недоставлено до абонента"
    #    "failed"       "Сообщение недоставлено из-за ошибки на платформе"
    #    "delayed"      "Было указано отложенное время отправки и сообщение ожидает его"
    #    "cancelled"    "Сообщение было отменено вручную на нашей платформе"

    # => SMS status check response codes:
    #    "ok"                           "Запрос успешно обработан"
    #    "error-system"                 "Произошла системная ошибка"
    #    "error-provider-id-unknown"    "Сообщение с таким идентификатором не найдено"

    def self.status(id)
      establish_connection.start do |http|
        request = Net::HTTP::Get.new(status_url id)
        response = http.request(request)
        body = response.body.split(';')
        return body[0], body[2] # code, status
      end
    end

    def update_status
      return @status if @id.nil?
      code, status = self.class.status(@id)
      return code unless code == 'ok'
      @status = status
    end

    # What for?
    # def to_json
    #   {:url => "#{server}:#{port}#{url}", :sms_message => message}.to_json
    # end

    private

      def self.establish_connection
        port = @@ssl ? @@ssl_port : @@port
        http = Net::HTTP.new(@@server, port)
        http.use_ssl = @@ssl
        http.cert_store = @@cert_store
        http
      end

      def validate!
        raise ArgumentError, "Phone should be assigned to #{self.class}." if @phone.nil?
        raise ArgumentError, "Phone number should contain only numbers. Minimum length is 10. #{@phone.inspect} is given." unless @phone =~ /^[0-9]{10,}$/
        raise ArgumentError, "Subject should be assigned to #{self.class}." if @subject.nil?
        raise ArgumentError, "Message should be assigned to #{self.class}." if @message.nil?
      end

      def self.init_cert_store cert
        raise ArgumentError, "Path to certificate should be defined for #{self}." if cert.nil?
        raise ArgumentError, "Certificate file '#{File.expand_path(cert)}' does not exist." unless File.exist?(cert)
        cert_store = OpenSSL::X509::Store.new
        cert_store.add_cert OpenSSL::X509::Certificate.new File.read(cert)
        cert_store
      end

      def self.validate_settings!
        raise ArgumentError, "Login should be defined for #{self}." if @@login.nil?
        raise ArgumentError, "Password should be defined for #{self}." if @@password.nil?
        raise ArgumentError, "Server should be defined for #{self}." if @@server.nil?
        raise ArgumentError, "Port should be defined for #{self}." if @@port.nil?
        raise ArgumentError, "Port for ssl should be defined for #{self}." if @@ssl_port.nil?
        raise ArgumentError, "Port should contain only numbers. #{@@port.inspect} is given." unless @@port.instance_of?(Fixnum)
        raise ArgumentError, "Port for ssl should contain only numbers. #{@@ssl_port.inspect} is given." unless @@ssl_port.instance_of?(Fixnum)
      end

      def send_url
        message = @@translit ? Translit.convert(@message) : @message
        "/revoup/connector0/send?login=#{@@login}&password=#{@@password}&" +
        "subject[0]=#{@subject}&address[0]=#{@phone}&text[0]=#{URI.encode(message)}"
      end

      def self.status_url msg_id
        "/revoup/connector0/status?login=#{@@login}&password=#{@@password}&" +
        "providerId[0]=#{msg_id}"
      end

  end
end
