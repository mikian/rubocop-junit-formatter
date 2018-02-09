require 'rexml/document'

module RuboCop
  module Formatter
    class JUnitFormatter < BaseFormatter
      # This gives all cops - we really want all _enabled_ cops, but
      # that is difficult to obtain - no access to config object here.
      COPS = Cop::Cop.all

      def started(_target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @testsuites = REXML::Element.new('testsuites', @document)
        @testsuite = REXML::Element.new('testsuite', @testsuites).tap do |el|
          el.add_attributes('name' => 'rubocop')
          el.add_attributes('timestamp' => Time.now.getutc)
        end
        # Create one empty testcase to avoid jenkins failure on empty results
        REXML::Element.new('testcase', @testsuite)
      end

      def file_finished(file, offences)
        # One test case per offense per cop per file
        test_count = COPS.length
        failure_count = 0
        offences.group_by(&:cop_name).each do |cop_name, offences_for_cop|
          REXML::Element.new('testcase', @testsuite).tap do |f|
            f.attributes['classname'] = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').tr('/', '.')
            f.attributes['name']      = cop_name

            # One failure per offence.  Zero failures is a passing test case,
            # for most surefire/nUnit parsers.
            offences_for_cop.each do |offence_for_cop|
              REXML::Element.new('failure', f).tap do |e|
                e.attributes['type'] = cop_name
                e.attributes['message'] = offence_for_cop.message
                e.add_text offence_for_cop.location.to_s
              end
              failure_count += 1
            end
          end
        end
        @testsuite.tap do |el|
          el.add_attributes('tests' => test_count)
          el.add_attributes('failures' => failure_count)
        end

        if failure_count == 0
          REXML::Element.new('testcase', @testsuite).tap do |s|
            s.add_attributes('name' => 'There were 0 offences. All tests passed.')
          end
        end
      end

      def finished(_inspected_files)
        @document.write(output, 2)
      end
    end
  end
end
