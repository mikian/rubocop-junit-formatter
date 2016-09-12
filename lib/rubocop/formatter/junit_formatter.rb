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

            def file_finished(file, offences)
                # One test case per cop per file
                tests = 0
                failures = 0
                COPS.each do |cop|
                    tests = tests += 1
                    REXML::Element.new('testcase', @testsuite).tap do |f|
                        f.attributes['classname'] = file.gsub(/\.rb\Z/, '').gsub("#{Dir.pwd}/", '').gsub('/', '.')
                        f.attributes['name']      = cop.cop_name

                        # One failure per offence.  Zero failures is a passing test case,
                        # for most surefire/nUnit parsers.
                        offences.select {|offence| offence.cop_name == cop.cop_name}.each do |offence|
                            REXML::Element.new('failure', f).tap do |e|
                                e.attributes['type'] = cop.cop_name
                                e.attributes['message'] = offence.message
                                e.add_text offence.location.to_s
                            end
                            failures = failures += 1
                        end
                    end
                end

                @testsuite.tap do |el|
                    el.add_attributes('tests' => tests)
                    el.add_attributes('failures' => failures)
                end

                if failures == 0
                    REXML::Element.new('testcase', @testsuite).tap do |s|
                        s.add_attributes('name' => 'There were 0 offences. All tests passed.')
                    end
                end
            end

            def finished(inspected_files)
                @document.write(output, 2)
            end
        end
    end
end
