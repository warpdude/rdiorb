require 'rubygems'
require 'json'

module Rdio

  class BaseObj

    attr_reader :api
    attr_accessor :key

    def initialize(api)
      @api = api
    end

  end

  class BaseApi

    def initialize(key,secret)
      @oauth = RdioOAuth.new key,secret
      @access_token = nil
    end

    def return_object(type,method,args)
      json = call method,args
      create_object type,json
    end

    def call(method,args)
      args['method'] = method
      args_str = args.map {|k,v| k.to_s + '=' + BaseApi.key(v).to_s}.join '&'
      url = 'http://api.rdio.com/1/'
      resp,data = access_token.post url,args
      return data
    end

    def keys(objs)
      objs.map {|x| BaseApi.to_s x}
    end

    private

    def self.key(v)
      return (v.kind_of? BaseObj) ? v.key : v
    end

    def to_o(base_type,v)
      s = v.to_s
      if not s
        return nil
      end
      if s == 'nil'
        return nil
      end
      if s =~ /^\d+/
        if base_type
          v = base_type.new self
          v.key = s.to_i
          return v
        end
        return s.to_i
      end
      if s =~ /^\d+\.?\d*$/
        return s.to_f
      end
      if s == 'true'
        return true
      end
      if s == 'false'
        return false
      end
      if s =~ /^\[.*\]$/
        s = s.gsub /^\[/,''
        s = s.gsub /\]$/,''
        return s.split(',').map {|x| to_o base_type,x}
      end
      return s
    end
    
    def camel2underscores(s)
      while s.match /([A-Z]+)/
        s = s.gsub /#{$1}/,'_'+$1.downcase
      end
      s
    end

    def create_object(type,json)
      obj = JSON.parse json
      status = obj['status']
      if status == 'ok'
        result = obj['result']
        if type == true
          return true
        end
        if type == false
          return false
        end
        if type == Boolean or type == String or type == Fixnum or type == Float
          return to_o type,res
        end
        res = type.new self
        result.each do |k,v|
          sym = (camel2underscores(k)+'=').to_sym
          o = to_o type,v
          res.send sym,o
        end
        return res
      end
      if status == 'error'
        raise Exception.new obj['message']
      end
      raise Exception.new status
    end

    def access_token
      if not @access_token
        @access_token = @oauth.access_token
      end
      @access_token
    end

  end

end
