require 'rexml/document'

module RestClient
	# This is the base RestClient exception class. Rescue it if you want to
	# catch any exception that your request might raise
	class Exception < RuntimeError
		def message(default=nil)
			self.class::ErrorMessage
		end
	end

	# A redirect was encountered; caught by execute to retry with the new url.
	class Redirect < Exception
		ErrorMessage = "Redirect"

		attr_accessor :url
		def initialize(url)
			@url = url
		end
	end

	# Authorization is required to access the resource specified.
	class Unauthorized < Exception
		ErrorMessage = 'Unauthorized'
	end

	# No resource was found at the given URL.
	class ResourceNotFound < Exception
		ErrorMessage = 'Resource not found'
	end

	# The server broke the connection prior to the request completing.
	class ServerBrokeConnection < Exception
		ErrorMessage = 'Server broke connection'
	end

	# The server took too long to respond.
	class RequestTimeout < Exception
		ErrorMessage = 'Request timed out'
	end

	# The request failed, meaning the remote HTTP server returned a code other
	# than success, unauthorized, or redirect.
	#
	# The exception message attempts to extract the error from the XML, using
	# format returned by Rails: <errors><error>some message</error></errors>
	#
	# You can get the status code by e.http_code, or see anything about the
	# response via e.response.  For example, the entire result body (which is
	# probably an HTML error page) is e.response.body.
	class RequestFailed < Exception
		attr_accessor :response

		def initialize(response=nil)
			@response = response
		end

		def http_code
			@response.code.to_i if @response
		end

		def message(default="Unknown error, HTTP status code #{http_code}")
			return default unless @response
			parse_error_xml rescue default
		end

		def parse_error_xml
			xml_errors = REXML::Document.new(@response.body).elements.to_a("//errors/error")
			xml_errors.empty? ? raise : xml_errors.map { |a| a.text }.join(" / ")
		end

		def to_s
			message
		end
	end
end

# backwards compatibility
class RestClient::Request
	Redirect = RestClient::Redirect
	Unauthorized = RestClient::Unauthorized
	RequestFailed = RestClient::RequestFailed
end
