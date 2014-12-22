require 'socket'

module Marginalia
  module Comment
    mattr_accessor :components, :lines_to_ignore
    Marginalia::Comment.components ||= [:application, :controller, :action]

    def self.update!(controller = nil)
      @controller = controller
    end

    def self.construct_comment
      ret = ''
      self.components.each do |c|
        component_value = self.send(c)
        if component_value.present?
          ret << "#{c.to_s}:#{component_value.to_s},"
        end
      end
      ret.chop!
      ret
    end

    def self.clear!
      @controller = nil
    end

    private
      def self.application
        if defined?(Rails.application)
          Marginalia.application_name ||= Rails.application.class.name.split("::").first
        else
          Marginalia.application_name ||= "rails"
        end

        Marginalia.application_name
      end

      def self.controller
        @controller.controller_name if @controller.respond_to? :controller_name
      end

      def self.controller_with_namespace
        @controller.class.name if @controller
      end

      def self.action
        @controller.action_name if @controller.respond_to? :action_name
      end

      def self.line
        Marginalia::Comment.lines_to_ignore ||= /\.rvm|gem|vendor\/|marginalia|rbenv/
        root = if defined?(Rails) && Rails.respond_to?(:root)
          Rails.root.to_s
        elsif defined?(RAILS_ROOT)
          RAILS_ROOT
        end

        last_line = nil
        for line in caller
          if root && line.starts_with?(root)
            line = line[root.length..-1]
          end
          if line !~ Marginalia::Comment.lines_to_ignore
            last_line = line
            break
          end
        end
        last_line
      end

      def self.hostname
        @cached_hostname ||= Socket.gethostname
      end

      def self.pid
        Process.pid
      end

      def self.request_id
        if @controller.respond_to?(:request) && @controller.request.respond_to?(:uuid)
          @controller.request.uuid
        end
      end
  end

end
