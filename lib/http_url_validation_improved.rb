require 'net/http'
require 'addressable/uri'
require 'socket'

module ActiveRecord
  module Validations
    module ClassMethods

      # Validates a URL.
      def validates_http_url(*attr_names)
        configuration = {
          :message_not_accessible => "is not accessible when we tried the link",
          :message_wrong_content => "is not of the appropriate content type",
          :message_moved_permanently => "has moved permanently",
          :message_url_format => "is not formatted correctly. (Missing 'http://'?)"
        }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
        validates_each(attr_names, configuration) do |record, attr_name, value|

          # Ignore blank URLs, these can be validated with validates_presence_of
          if value.nil? or value.empty?
            next
          end

          begin
            moved_retry ||= false
            not_allowed_retry ||= false
            retry_without_headers ||= false
            # some domains will block requests that come in more frequently than 1 per second
            sleepy_domains = ['wikipedia.org']
            sleep_interval = 2 # 2 to be on the safe side
            must_sleep ||= false
            response = nil

            # resolve to url escaped version of URL
            # value = URI.escape(value)
            # updated to allow unicode values
            # escaping shouldn't be necessary
            must_sleep = sleepy_domains.select { |d| value.include?(d) }.size > 0


            url = Addressable::URI.parse(value)

            # Check Formatting
            # moved to use the URI library's logic
            # now allows ftp and other non-http(s) protocols
            # must have a protocol specified
            raise unless url.scheme
            # must have a domain name specified
            raise unless url.host

            url.path = "/" if url.path.length < 1
            http = Net::HTTP.new(url.host, (url.scheme == 'https') ? 443 : 80)
            if url.scheme == 'https'
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end
            headers = Object.const_defined?('SITE_URL') ? { "User-Agent" => "#{SITE_URL} link checking mechanism (http://github.com/kete/http_url_validation_improved) via Ruby Net/HTTP" } : { "User-Agent" => "Ruby Net/HTTp used for link checking mechanism (http://github.com/kete/http_url_validation_improved)" }
            response = if not_allowed_retry
                         sleep sleep_interval if must_sleep

                         if retry_without_headers
                           http.request_get(url.path) {|r|}
                         else
                           http.request_get(url.path, headers) {|r|}
                         end
                       else
                         http.request_head(url.path, headers)
                       end
            # response = not_allowed_retry ? http.request_get(url.path) {|r|} : http.request_head(url.path)
            # Comment out as you need to
            allowed_codes = [
                             Net::HTTPMovedPermanently,
                             Net::HTTPOK,
                             Net::HTTPCreated,
                             Net::HTTPAccepted,
                             Net::HTTPNonAuthoritativeInformation,
                             Net::HTTPPartialContent,
                             Net::HTTPFound,
                             Net::HTTPTemporaryRedirect,
                             Net::HTTPSeeOther,
                             Timeout::Error
                            ]
            # If response is not allowed, raise an error
            raise unless allowed_codes.include?(response.class)
            # Check if the model requires a specific content type
            unless configuration[:content_type].nil?
              record.errors.add(attr_name, configuration[:message_wrong_content]) if response['content-type'].index(configuration[:content_type]).nil?
            end
          rescue Timeout::Error
            record.errors.add(attr_name, configuration[:message_not_accessible] + ". The website took too long to respond." )
          rescue
            # Has the page moved?
            if response.is_a?(Net::HTTPMovedPermanently)
              unless moved_retry
                moved_retry = true
                value += "/" # In case webserver is just adding a /
                retry
              else
                record.errors.add(attr_name, configuration[:message_moved_permanently])
              end
            elsif response.is_a?(Net::HTTPMethodNotAllowed) || response.is_a?(Net::HTTPInternalServerError)
              unless not_allowed_retry
                # Retry with a GET
                not_allowed_retry = true
                retry
              else
                if response.is_a?(Net::HTTPInternalServerError)
                  record.errors.add(attr_name, configuration[:message_not_accessible]+". The site link in question has had a problem. Please raise the issue with them and let them know that requests to the link break when coming from the automatic link checking mechanism on this site.")
                else
                  record.errors.add(attr_name, configuration[:message_not_accessible]+" (GET method not allowed)")
                end
              end
            elsif response.is_a?(Net::HTTPForbidden)
              # handle requests where particular variants are forbidden
              unless (not_allowed_retry && retry_without_headers)
                unless not_allowed_retry
                  # try a full request GET first (rather than just head)
                  not_allowed_retry = true
                  retry
                else
                  # try again but without headers (sometimes site refuse custom headers)
                  # for now, at least, this does a full GET request (rather than just head)
                  retry_without_headers = true
                  retry
                end
              else
                record.errors.add(attr_name, configuration[:message_not_accessible] + ". The website says the URL is Forbidden.")
              end
            else
              # if response is nil, then it's a format issue
              if response.nil?
                record.errors.add(attr_name, configuration[:message_url_format])
              else
                # Just Plain non-accessible
                record.errors.add(attr_name, configuration[:message_not_accessible]+". This is what the website in question returned to us: "+response.class.to_s)
              end
            end
          end
        end
      end

      def validates_http_domain(*attr_names)
        validates_each(attr_names) do |record, attr_name, value|
          # Set valid true on successful connect (all we need is one, one is all we need)
          failed = true
          possibilities = [value, "www."+value]
          possibilities.each do |url|
            begin
              temp = Socket.gethostbyname(url)
            rescue SocketError
              next
            end
            failed = false
            break
          end
          record.errors.add(attr_name, "cannot be resolved.") if failed
        end
      end
    end
  end
end
