require "rails_helper"

RSpec.describe CoursesController do
  let(:provider) { build(:provider) }
  let(:course) { build(:course, provider: provider) }

  before do
    stub_api_v3_resource(
      type: Course,
      params: {
        recruitment_cycle_year: Settings.current_cycle,
        provider_code: course.provider_code,
        course_code: course.course_code,
      },
      resources: course,
      include: %w[provider],
    )
  end

  describe "#apply" do
    let(:logger) { double(:logger) }

    it "redirects to correct apply destination" do
      get :apply, params: { provider_code: course.provider_code, course_code: course.course_code }
      expect(response).to redirect_to("https://www.apply-for-teacher-training.service.gov.uk/candidate/apply?providerCode=#{course.provider.provider_code}&courseCode=#{course.course_code}")
    end

    context "a course from University of Bolton" do
      let(:provider) { build(:provider, provider_code: "8N5") }
      let(:course) { build(:course, course_code: "V595", provider: provider) }

      it "redirects to University of Bolton's applications service" do
        get :apply, params: { provider_code: course.provider_code, course_code: course.course_code }
        expect(response).to redirect_to("https://evision.bolton.ac.uk/urd/sits.urd/run/siw_ipp_lgn.login?process=siw_ipp_app&code1=1101-D&code2=0001")
      end
    end

    it "writes to log" do
      allow(Rails).to receive(:logger).and_return(logger)
      expect(logger).to receive(:info).with("Course apply conversion. Provider: #{course.provider.provider_code}. Course: #{course.course_code}")

      get :apply, params: { provider_code: course.provider_code, course_code: course.course_code }
    end
  end
end
