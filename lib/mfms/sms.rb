# encoding: UTF-8
require 'net/http'
require 'openssl'
require 'uri'
require 'russian'

module Mfms
  class SMS

    attr_accessor :phone, :subject, :message, :account, :login, :password, :server, :cert, :port, :ssl_port, :ssl
    attr_reader :id, :status, :errors

    def initialize(data)
      @phone = data.fetch(:phone, nil)
      @subject = data.fetch(:subject, nil)
      @message = data.fetch(:message, nil)
      @status = 'not-sent'
      account = "@@#{data[:account]}".to_sym
      account_variable = if account.present? && self.class.class_variables.include?(account)
                           account
                         else
                           self.class.default_account
                         end
      account_settings = self.class.class_variable_get(account_variable)
      @login = account_settings[:login]
      @connector = account_settings[:connector]
      @password = account_settings[:password]
      @ssl = account_settings[:ssl]
      @ssl_port = account_settings[:ssl_port]
      @port = account_settings[:port]
      @cert = account_settings[:cert]
      @server = account_settings[:server]
      @translit = data.fetch(:translit, account_settings[:translit])
      @priority = data.fetch(:priority, account_settings[:priority])
      @errors = []
      validate!
    end

    def self.settings=(settings=[])
      settings.each do |setting|
        account = setting.keys.first
        account_settings = setting[account]
        account_settings[:cert] = init_cert_store(account_settings[:cert])
        account_settings[:ssl] = account_settings.fetch(:ssl, true)
        account_settings[:translit] = account_settings.fetch(:translit, false)
        account_settings[:additional_args] = account_settings.fetch(:additional_args, nil)
        account_settings[:priority] = account_settings.fetch(:priority, nil)
        if settings_valid?(account_settings)
          self.class_variable_set("@@#{account}", account_settings)
        end
      end
    end

    def self.default_account
      default_account = nil
      Array.wrap(class_variables).each do |account|
        if class_variable_get(account.to_s).has_key?(:default)
          default_account = account
          break
        end
      end
      default_account || raise(ArgumentError, 'One of the accounts should be specified by default')
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
      unless @phone =~ /^[0-9]{10,}$/
        raise ArgumentError, 'Phone number should contain only numbers. Minimum'+
                             "length is 10. #{@phone.inspect} is given."
      end
      raise ArgumentError, "Subject should be assigned to #{self.class}." if @subject.nil?
      raise ArgumentError, "Message should be assigned to #{self.class}." if @message.nil?
      if @priority && !%w(low normal high realtime).include?(@priority)
        raise ArgumentError, 'Priority is not valid.'
      end
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

    def self.settings_valid?(settings)
      [:login, :password, :server, :port, :ssl_port].each do |attr|
        if settings[attr].nil?
          raise ArgumentError, "#{attr.to_s.gsub(/_/,' ').capitalize} should be defined for #{self}."
        end
      end
      [:port, :ssl_port].each do |attr|
        unless settings[attr].instance_of?(Fixnum)
          raise ArgumentError,
                "#{attr.to_s.gsub(/_/,' ').capitalize} should contain only numbers. #{settings[attr].inspect} is given."
        end
      end
      true
    end

    def send_url
      message = @translit ? Russian.translit(@message) : @message
      url = "/revoup/#{@connector}/send?login=#{@login}&password=#{@password}&" +
          "subject[0]=#{@subject}&address[0]=#{@phone}&text[0]=#{URI.encode(message)}"
      url += "&priority=#{@priority}" if @priority
      url
    end

    def status_url(msg_id)
      "/revoup/#{@connector}/status?login=#{@login}&password=#{@password}&providerId[0]=#{msg_id}"
    end

  end
end
