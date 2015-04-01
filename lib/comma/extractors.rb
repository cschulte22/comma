module Comma

  class Extractor

    def initialize(instance, &block)
      @instance = instance
      @block = block
      @results = []
    end

    def results
      instance_eval &@block
      @results
    end

    def id(*args)
      method_missing(:id, *args)
    end
  end

  class HeaderExtractor < Extractor
    @headers_hit = []
    def method_missing(sym, *args, &block)
      if sym == :custom_columns
        if block
#           if @instance.class.in? [CourtCase, Company, Client, Expense, TimeEntry]
# #            binding.pry if @instance.class.in? [Company] # fix should be the same for Client and Company
#            # We want to collect all the custom field headers for the given scope
#             scope = CustomField.class_to_scope @instance.class
#   #          binding.pry if @instance.class.name.in? ['TimeEntry']
#             headers = @instance.firm.custom_fields.send(scope).map(&:name)
#             @results += headers unless @results.include? headers
#           else
            # if it's not a new custom fields class, do things the way we used to
          @results += @instance.instance_eval(&block).collect {|arr| arr.first}
          # end
        else
          @results += @instance.instance_eval(args.to_s).collect {|arr| arr.first}
        end
      elsif sym == :custom_fields
#       binding.pry if @instance.class.in? [Company] # fix should be the same for Client and Company
       # We want to collect all the custom field headers for the given scope
        scope = CustomField.class_to_scope @instance.class
#          binding.pry if @instance.class.name.in? ['TimeEntry']
        headers = @instance.firm.custom_fields.send(scope).map(&:name)
        @results += headers
      else
        @results << sym.to_s.humanize if args.blank?
        args.each do |arg|
          case arg
          when Hash
            arg.each do |k, v|
              @results << ((v.is_a? String) ? v : v.to_s.humanize)
            end
          when Symbol
            @results << arg.to_s.humanize
          when String
            @results << arg
          else
            raise "Unknown header symbol #{arg.inspect}"
          end
        end
      end
    end
  end

  class DataExtractor < Extractor

    def method_missing(sym, *args, &block)
      if sym == :custom_columns || sym == :custom_fields
        if block
          @results += @instance.instance_eval(&block).collect {|arr| arr.last}
        else
          @results += @instance.instance_eval(args.to_s).collect {|arr| arr.last}
        end
      else
        if args.blank?
          result = block ? yield(@instance.send(sym)) : @instance.send(sym)
          @results << result.to_s
        end

        args.each do |arg|
          case arg
          when Hash
            arg.each do |k, v|
              if block
                @results << (@instance.send(sym).nil? ? '' : yield(@instance.send(sym).send(k)).to_s )
              else
                @results << (@instance.send(sym).nil? ? '' : @instance.send(sym).send(k).to_s )
              end
            end
          when Symbol
            if block
              @results << (@instance.send(sym).nil? ? '' : yield(@instance.send(sym).send(arg)).to_s)
            else
              @results << ( @instance.send(sym).nil? ? '' : @instance.send(sym).send(arg).to_s )
            end
          when String
            @results << (block ? yield(@instance.send(sym)) : @instance.send(sym)).to_s
          else
            raise "Unknown data symbol #{arg.inspect}"
          end
        end
      end
    end
  end
end
