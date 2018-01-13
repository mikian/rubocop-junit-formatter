require 'rexml/document'

module RuboCop
  module Formatter
    class JUnitFormatter < BaseFormatter
      
      # This gives all cops - we really want all _enabled_ cops, but
      # that is difficult to obtain - no access to config object here.
      COPS = Cop::Cop.all
      
      def started(target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @testsuites = REXML::Element.new('testsuites', @document)
        @testsuite = REXML::Element.new('testsuite', @testsuites).tap do |el|
          el.add_attributes('name' => 'rubocop')
          el.add_attributes('timestamp' => Time.now.getutc)
        end
      end

      $suitetests = 0
      $suitetestfailures = 0
      def file_finished(file, offences)
        testcasetests = 0
        testcasefailures = 0
        testcaseoffenses = 0
        lastcopname = ''
        # One test case per cop per file
        COPS.each do |cop|
          REXML::Element.new('testcase', @testsuite).tap do |f|
            f.attributes['classname'] = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').gsub('/', '.')
            f.attributes['name']      = cop.cop_name
            testcasetests = testcasetests += 1            
            # One failure per offence.  Zero failures is a passing test case,
            # for most surefire/nUnit parsers.
            offences.select {|offence| offence.cop_name == cop.cop_name}.each do |offence|
              REXML::Element.new('failure', f).tap do |e|
                e.attributes['type'] = cop.cop_name
                e.attributes['message'] = offence.message
                path = Pathname.new(file).relative_path_from(Pathname.new(Dir.pwd))
                e.add_text "#{path.to_s}:#{offence.line.to_s}:#{offence.real_column}"
              end
              if (cop.cop_name != lastcopname )
                lastcopname = "#{cop.cop_name}"
                testcasefailures = testcasefailures += 1
              end
              testcaseoffenses = testcaseoffenses += 1                           
            end
          end
        end
        $suitetests = $suitetests + testcasetests
        $suitetestfailures = $suitetestfailures + testcasefailures
        @testsuite.tap do |el|
          el.add_attributes('tests' => $suitetests)
          el.add_attributes('failures' => $suitetestfailures)
        end
        if testcaseoffenses == 0
          REXML::Element.new('testcase', @testsuite).tap do |s|
            s.add_attributes('name' => "There were #{testcaseoffenses} offences out of #{testcasetests}. All tests passed.")
          end
        else
          REXML::Element.new('testcase', @testsuite).tap do |s|            
            s.add_attributes('name' => "There were #{testcaseoffenses} offences in #{testcasefailures} failed tests out of #{testcasetests}.")
          end                  
        end
      end

      def finished(inspected_files)
        @document.write(output, 2)
      end

    end
  end
end
