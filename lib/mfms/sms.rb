# encoding: UTF-8
require 'net/http'
require 'openssl'
require 'uri'
require 'russian'

module Mfms
  class SMS

    attr_accessor :phone, :subject, :message, :account, :login, :password, :server, :cert, :port, :ssl_port, :ssl
    attr_reader :id, :status, :errors

    def initialize(phone, subject, message, translit = nil, account = nil)
      @phone = phone
      @subject = subject
      @message = message
      @status = 'not-sent'
      account = "@@#{account}".to_sym
      account_variable = if account.present? && self.class.class_variables.include?(account)
                           account
                         else
                           self.class.class_variables.select{|sym| sym.to_s.include?('revoup0')}.first
                         end
      account_settings = Mfms::SMS.class_variable_get(account_variable)
      @login = account_settings[:login]
      @password = account_settings[:password]
      @ssl = account_settings[:ssl]
      @ssl_port = account_settings[:ssl_port]
      @port = account_settings[:port]
      @cert = account_settings[:cert]
      @server = account_settings[:server]
      @translit = translit.nil? ? account_settings[:translit] : translit
      @errors = []
      validate!
    end

    def self.settings=(settings=[])
      settings.each do |setting|
        account = setting.keys.first
        account_settings = setting[account]
        account_settings[:cert] = init_cert_store(account_settings[:cert])
        account_settings[:ssl] = account_settings[:ssl].presence || true
        account_settings[:translit] = account_settings[:translit].presence || false
        class_variable_set("@@#{account}", account_settings)
        validate_settings!(account_settings)
      end
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
      establish_connection.start do |http|
        request = Net::HTTP::Get.new(send_url)
        response = http.request(request)
        body = response.body.split(';')
        if body[0] == 'ok'
          @status = 'sent'
          @id = body[2]
          true
        else
          @errors << body[0]
          false
        end
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

    def validate!
      raise ArgumentError, "Phone should be assigned to #{self.class}." if @phone.nil?
      raise ArgumentError, "Phone number should contain only numbers. Minimum length is 10. #{@phone.inspect} is given." unless @phone =~ /^[0-9]{10,}$/
      raise ArgumentError, "Subject should be assigned to #{self.class}." if @subject.nil?
      raise ArgumentError, "Message should be assigned to #{self.class}." if @message.nil?
    end

    private

    def establish_connection
      port = @ssl ? @ssl_port : @port
      http = Net::HTTP.new(@server, port)
      http.use_ssl = @ssl
      http.cert_store = @cert
      http
    end

    def self.init_cert_store(cert)
      raise ArgumentError, "Path to certificate should be defined for #{self}." if cert.nil?
      raise ArgumentError, "Certificate file '#{File.expand_path(cert)}' does not exist." unless File.exist?(cert)
      cert_store = OpenSSL::X509::Store.new
      cert_store.add_cert OpenSSL::X509::Certificate.new File.read(cert)
      cert_store
    end

    def self.validate_settings!(settings)
      raise ArgumentError, "Login should be defined for #{self}." if settings[:login].nil?
      raise ArgumentError, "Password should be defined for #{self}." if settings[:password].nil?
      raise ArgumentError, "Server should be defined for #{self}." if settings[:server].nil?
      raise ArgumentError, "Port should be defined for #{self}." if settings[:port].nil?
      raise ArgumentError, "Port for ssl should be defined for #{self}." if settings[:ssl_port].nil?
      raise ArgumentError, "Port should contain only numbers. #{settings[:port].inspect} is given." unless settings[:port].instance_of?(Fixnum)
      raise ArgumentError, "Port for ssl should contain only numbers. #{settings[:ssl_port].inspect} is given." unless settings[:ssl_port].instance_of?(Fixnum)
    end

    def send_url
      message = @translit ? Russian.translit(@message) : @message
      "/revoup/connector0/send?login=#{@login}&password=#{@password}&" +
          "subject[0]=#{@subject}&address[0]=#{@phone}&text[0]=#{URI.encode(message)}"
    end

    def self.status_url(msg_id)
      "/revoup/connector0/status?login=#{@login}&password=#{@password}&" +
          "providerId[0]=#{msg_id}"
    end

  end
end
