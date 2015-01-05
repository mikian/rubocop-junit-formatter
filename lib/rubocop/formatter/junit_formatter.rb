require 'rexml/document'

module RuboCop
  module Formatter
    class JUnitFormatter < BaseFormatter
      def started(target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @testsuites = REXML::Element.new('testsuites', @document)
        @testsuite = REXML::Element.new('testsuite', @testsuites).tap do |el|
          el.add_attributes('name' => 'rubocop')
        end
      end

      def file_finished(file, offences)
        return if offences.empty?

        offences.group_by(&:cop_name).each do |cop, cop_offences|
          REXML::Element.new('testcase', @testsuite).tap do |f|
            f.attributes['classname'] = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').gsub('/', '.')
            f.attributes['name']      = cop

            cop_offences.each do |offence|
              REXML::Element.new('failure', f).tap do |e|
                e.attributes['type'] = cop
                e.attributes['message'] = offence.message
                e.add_text offence.location.to_s
              end
            end
          end
        end
      end

      def finished(inspected_files)
        @document.write(output, 2)
      end
    end
  end
end
