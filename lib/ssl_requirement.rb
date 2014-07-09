require "#{File.dirname(__FILE__)}/url_rewriter"

# Copyright (c) 2005 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
module SslRequirement
  mattr_accessor :ssl_host, :non_ssl_host

  mattr_writer :disable_ssl_check, :ssl_all
  def self.disable_ssl_check?
    @@disable_ssl_check ||= false
  end
  def self.ssl_all?
    @@ssl_all ||= false
  end

  # called when Module is mixed in
  def self.included(controller)
    controller.extend(ClassMethods)
    controller.before_filter(:ensure_proper_protocol)
  end

  module ClassMethods
    # Specifies that the named actions requires an SSL connection to be performed (which is enforced by ensure_proper_protocol).
    def ssl_required(*actions)
      write_inheritable_array(:ssl_required_actions, actions)
    end

    def ssl_exceptions(*actions)
      write_inheritable_array(:ssl_required_except_actions, actions)
    end

    def ssl_allowed(*actions)
      write_inheritable_array(:ssl_allowed_actions, actions)
    end
    alias_method :ssl_not_required, :ssl_allowed
  end

  protected
  # Returns true if the current action is supposed to run as SSL
  def ssl_required?
    return true if SslRequirement.ssl_all?

    required = (self.class.read_inheritable_attribute(:ssl_required_actions) || [])
    except  = self.class.read_inheritable_attribute(:ssl_required_except_actions)

    unless except
      required.include?(action_name.to_sym)
    else
      !except.include?(action_name.to_sym)
    end
  end

  def ssl_allowed?
    (self.class.read_inheritable_attribute(:ssl_allowed_actions) || []).include?(action_name.to_sym)
  end

  # normal ports are the ports used when no port is specified by the user to the browser
  # i.e. 80 if the protocol is http, 443 is the protocol is https
  NORMAL_PORTS = [80, 443]

  private
  def ensure_proper_protocol
    return true if SslRequirement.disable_ssl_check?
    return true if ssl_allowed? && !SslRequirement.ssl_all?

    if ssl_required? && !request.ssl?
      redirect_to determine_redirect_url(request, true)
      flash.keep
      return false
    elsif request.ssl? && !ssl_required?
      redirect_to determine_redirect_url(request, false)
      flash.keep
      return false
    end
  end

  def determine_redirect_url(request, ssl)
    protocol = ssl ? "https" : "http"
    "#{protocol}://#{determine_host_and_port(request, ssl)}#{request.request_uri}"
  end

  def determine_host_and_port(request, ssl)
    request_host = request.host
    request_port = request.port

    if ssl
      "#{(ssl_host || request_host)}#{determine_port_string(request_port)}"
    else
      "#{(non_ssl_host || request_host)}#{determine_port_string(request_port)}"
    end
  end

  def determine_port_string(port)
    unless port_normal?(port)
      ":#{port}"
    else
      ""
    end
  end

  def port_normal?(port)
    NORMAL_PORTS.include?(port)
  end
end
