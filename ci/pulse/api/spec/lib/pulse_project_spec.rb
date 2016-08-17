require 'spec_helper'
require 'pulse_project'

describe PulseProject do
  let(:proxy) { double :proxy }
  let(:url) { 'http://something.example.com:443' }
  let(:project_name) { 'Will Pass' }

  before { allow(PulseProject::Proxy).to receive(:new).with(url).and_return proxy }
  before { allow(proxy).to receive(:latest_builds_for_project).with(project_name).and_return proxy_response }

  subject { described_class.new(url, project_name) }

  describe '#checkman_json' do
    subject { super().checkman_json }

    context 'when the project has passed' do
      let(:proxy_response) do
        [
            {
                'succeeded' => true,
                'completed' => true,
            }
        ]
      end

      it { is_expected.to include('result' => true) }
      it { is_expected.to include('changing' => false) }
    end

    context 'when the project is in progress' do
      let(:proxy_response) do
        [
            {
                'succeeded' => false,
                'completed' => false,
            },
        ]
      end

      context 'when the previous project succeded' do
        let(:proxy_response) do
          super() + [
              {
                  'succeeded' => true,
                  'completed' => true,
              },
          ]
        end

        it { is_expected.to include('result' => true) }
        it { is_expected.to include('changing' => true) }
      end

      context 'when the previous project failed' do
        let(:proxy_response) do
          super() + [
              {
                  'succeeded' => false,
                  'completed' => true,
              },
          ]
        end

        it { is_expected.to include('result' => false) }
        it { is_expected.to include('changing' => true) }
      end
    end

    context 'when the project has failed' do
      let(:proxy_response) do
        [
            {
                'succeeded' => false,
                'completed' => true,
            }
        ]
      end

      it { is_expected.to include('result' => false) }
      it { is_expected.to include('changing' => false) }
    end

    context 'when the project has a build identifier' do
      let(:proxy_response) do
        [
            {
                'succeeded' => true,
                'completed' => true,
                'id' => 37
            }
        ]
      end

      it { is_expected.to include('url' => "http://something.example.com:443/browse/projects/Will%20Pass/builds/37/") }
      it { expect(subject['info']).to include(["Build", 37]) }
    end

    context 'when the project has not previously run' do
      let(:proxy_response) { [] }

      it { is_expected.to include('url' => "http://something.example.com:443/browse/projects/Will%20Pass") }
      it { is_expected.to include('changing' => false) }
      it { is_expected.to include('result' => nil) }
      it { expect(subject['info']).to include(["Build", "not yet started"]) }
    end

    context 'when the project is completed' do
      let(:proxy_response) do
        [
            {
                'succeeded' => true,
                'completed' => true,
                'progress' => 100,
                'endTimeMillis' => 1234567890000,
                'startTimeMillis' => 1234494000000,
                'errorCount' => 2,
                'warningCount' => 0,
                'owner' => "Bob",
                'revision' => "SomeSHA"
            }
        ]
      end

      it { expect(subject['info']).to include(["Duration", "20:31:30"]) }
      it { expect(subject['info']).to include(["Progress", "100%"]) }
      it { expect(subject['info']).to include(["Errors", 2]) }
      it { expect(subject['info']).to include(["Warnings", 0]) }
      it { expect(subject['info']).to include(["Owner", "Bob"]) }
      it { expect(subject['info']).to include(["Revision", "SomeSHA"]) }
    end

    context 'when the project is a personal build' do
      let(:proxy_response) do
        [
            {
                'succeeded' => true,
                'completed' => true,
                'owner' => "Bob",
                'personal' => true
            }
        ]
      end

      it { expect(subject['info']).to include(["Owner", "Bob (Personal)"]) }
    end

    context 'when the project is in progress' do
      let(:proxy_response) do
        [
            {
                'succeeded' => false,
                'completed' => false,
                'progress' => -1,
                'startTime' => XMLRPC::DateTime.new(2015, 05, 25, 12, 15, 31)
            }
        ]
      end

      context 'and there was a previous build' do
        let(:proxy_response) do
          super() + [
              {
                  'succeeded' => true,
                  'completed' => true,
              },
          ]
        end

        it { expect(subject['info']).to include(["Started", "12:15PM 05/25/2015 UTC"]) }
        it { expect(subject['info']).to include(["Duration", "N/A"]) }
        it { expect(subject['info']).to include(["Progress", "N/A"]) }
      end

      context 'when the project is pending to start' do
        let(:proxy_response) do
          [
              {
                  'succeeded' => false,
                  'completed' => false,
                  'progress' => -1,
                  'startTime' => XMLRPC::DateTime.new(1969, 12, 31, 15, 59, 59)
              }
          ]
        end

        it { expect(subject['info']).to include(["Started", "N/A"]) }
      end
    end

    context 'when the project contains test information' do
      let(:proxy_response) do
        [
            {
                'succeeded' => true,
                'completed' => true,
                'tests' => {
                  'total' => 100,
                  'errors' => 1,
                  'expectedFailures' => 2,
                  'failures' => 3,
                  'passed' => 4,
                  'skipped' => 5
                }
            }
        ]
      end

      it { expect(subject['info']).to include(["-", ""]) }
      it { expect(subject['info']).to include(["Tests", ""]) }
      it { expect(subject['info']).to include([" - Total", 100]) }
      it { expect(subject['info']).to include([" - Errors", 1]) }
      it { expect(subject['info']).to include([" - Expected Failures", 2]) }
      it { expect(subject['info']).to include([" - Failures", 3]) }
      it { expect(subject['info']).to include([" - Passed", 4]) }
      it { expect(subject['info']).to include([" - Skipped", 5]) }
    end
  end
end
