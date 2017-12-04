require "yaml"
require "pathname"
require "deep_merge"
require "json"

module Ansible
  module Inventory
    # Class to represent ansible inventory file in YAML
    class YAML
      @config = nil
      @file = ""

      # Creates an instance of Ansible::Inventory::YAML
      #
      # @param path [String] path to inventory file in YAML
      def initialize(file)
        @file = file
      end

      # Returns parsed inventory content
      #
      # @return [Hash] parsed inventory in hash
      def config
        return @config unless @config.nil?
        @config = load_file(@file)
        inventory_scripts.each do |f|
          json = run_and_return_json(f)
          @config["all"]["hosts"].deep_merge!(json)
        end
        @config.freeze
      end

      def load_file(file)
        ::YAML.load_file(file)
      end

      # Returns all file names in the directory where yaml config is
      #
      # @return [Array]
      def inventory_scripts
        dir = Pathname.new(@file).expand_path.dirname
        Dir["#{dir}/*"].select do |f|
          File.file?(f) &&
            File.executable?(f)
        end
      end

      # run the file, parse the output, and return the result
      #
      # @return [Hash]
      def run_and_return_json(file)
        result = `#{file}`
        begin
          json = JSON.parse(result)
        rescue StandardError => e
          raise "cannot parse file `#{file}`: #{e.message}"
        end
        json
      end

      # Returns an array of all groups, except `all`
      #
      # @return [Array] array of all groups in String
      def all_groups
        config.keys.reject { |k| k == "all" }
      end

      # Returns a host configuration in `all`
      #
      # @param host [String] name of host
      # @returns [Hash] ansible variables of the host, variable name as key
      def host(host)
        unless config["all"].key?("hosts")
          raise "group `all` must have `hosts` as key"
        end
        unless config["all"]["hosts"].key?(host)
          raise "cannot find `#{host}` in group `all`"
        end
        config["all"]["hosts"][host]
      end

      # Resolve all hosts in a group
      #
      # @param group [String] name of group
      # @return [Array] array of string of host names in a group, including
      #   `children` and `hosts` of the group
      def all_hosts_in(group)
        unless config.key?(group)
          raise "cannot find group `#{group}` in inventory"
        end
        hosts = hosts_of(group).keys
        children = children_of(group)
        children.each_key do |child|
          raise "cannot find group `#{child}`" unless config.key?(child)
          hosts += all_hosts_in(child)
        end
        hosts
      end

      # Returns `hosts` of a group
      #
      # @param group [String] name of group
      # @return [Hash] `hosts`
      def hosts_of(group)
        config[group].key?("hosts") ? config[group]["hosts"] : {}
      end

      # Returns `children` of a group
      #
      # @param group [String] name of group
      # @return [Array] `children` of the group
      def children_of(group)
        config[group].key?("children") ? config[group]["children"] : {}
      end
    end
  end
end
