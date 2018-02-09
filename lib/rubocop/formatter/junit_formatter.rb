require 'rexml/document'
require 'rubocop'

module RuboCop
  module Formatter
    # Inherit from Rubocop::Formatter::BaseFormatter
    class JUnitFormatter < BaseFormatter
      # This gives all cops - we really want all _enabled_ cops, but
      # that is difficult to obtain - no access to config object here.
      COPS = Cop::Cop.all
      $cop_count = COPS.length
      $suitetests = Hash.new do |h, k|
        h[k] = Hash.new(0)
      end

      def started(_target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @testsuites = REXML::Element.new('testsuites', @document)
        @testsuite = REXML::Element.new('testsuite', @testsuites).tap do |el|
          el.add_attributes('name' => 'rubocop')
          el.add_attributes('timestamp' => Time.now.getutc)
        end
        $suitetests[:suite][:cops_offended] # global total offended cops
        $suitetests[:suite][:rules_broken] # global total rules broken
      end

      def file_finished(file, offences)
        classname = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').tr('/', '.')
        # One test case per offense per cop per file
        offences.group_by(&:cop_name).each do |cop_name, rules_broken|
          REXML::Element.new('testcase', @testsuite).tap do |f|
            f.attributes['classname'] = classname
            f.attributes['name']      = cop_name
            # How many Cops does this file break, tallied per suite, cop, and file?
            $suitetests[:suite][:cops_offended] += 1
            $suitetests[cop_name][:offenses] += 1
            $suitetests[classname][:cops_offended] += 1
            # How many Rules does this file break, tallied per suite, cop, and file?
            $suitetests[:suite][:rules_broken] += rules_broken.length
            $suitetests[cop_name][:rules_broken] += rules_broken.length
            $suitetests[classname][:rules_broken] += rules_broken.length
            # One failure per offence.  Zero failures is a passing test case,
            # for most surefire/nUnit parsers.
            rules_broken.each do |rule_broken|
              REXML::Element.new('failure', f).tap do |e|
                e.attributes['type'] = cop_name
                e.attributes['message'] = rule_broken.message
                e.add_text rule_broken.location.to_s
              end
            end
            f.add_attributes('failures' => $suitetests[classname][:rules_broken])
          end
        end
        $suitetests[classname][:tests] += $cop_count
        $suitetests[:suite][:tests] += $cop_count
        # Per File Report
        REXML::Element.new('testcase', @testsuite).tap do |s|
          s.attributes['classname'] = classname
          s.add_attributes('name' => "#{$suitetests[classname][:failures] == 0 ? 'Success' : 'Cop Failures'}: #{classname}")
          s.add_attributes('tests' => $suitetests[classname][:tests])
          s.add_attributes('failures' => $suitetests[classname][:cops_offended])
        end
      end

      def finished(_inspected_files)
        @testsuite.tap do |el|
          el.add_attributes('tests' => $suitetests[:suite][:tests])
          el.add_attributes('failures' => $suitetests[:suite][:cops_offended])
        end
        @document.write(output, 2)
      end
    end
  end
end
