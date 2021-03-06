require "rails_helper"

feature "Qualifications filter", type: :feature do
  let(:filter_page) { PageObjects::Page::ResultFilters::Qualification.new }
  let(:results_page) { PageObjects::Page::Results.new }
  let(:courses_url) do
    "http://localhost:3001/api/v3/recruitment_cycles/2020/courses"
  end

  let(:base_parameters) { results_page_parameters }

  before do
    stub_subjects_request
  end

  describe "Qualification filter page" do
    before { filter_page.load }

    it "has the correct title and heading" do
      expect(page.title).to have_content("Filter by qualification")
      expect(page).to have_content("What you will get")
    end

    describe "back link" do
      before do
        stub_request(:get, courses_url)
          .with(query: base_parameters)
          .to_return(
            body: File.new("spec/fixtures/api_responses/ten_courses.json"),
            headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
          )
      end

      it "navigates back to the results page" do
        filter_page.load(query: { test: "params" })
        filter_page.back_link.click

        expect_page_to_be_displayed_with_query(
          page: results_page,
          expected_query_params: {
            "fulltime" => "false",
            "hasvacancies" => "true",
            "parttime" => "false",
            "qualifications" => %w[QtsOnly PgdePgceWithQts Other],
            "senCourses" => "false",
            "test" => "params",
          },
        )
      end
    end

    describe "validation" do
      context "when no qualification is selected" do
        it "shows an error message" do
          filter_page.find_courses.click

          expect(filter_page).to have_error
          expect(filter_page.qts_only).not_to be_checked
          expect(filter_page.pgde_pgce_with_qts).not_to be_checked
          expect(filter_page.other).not_to be_checked
        end
      end
    end
  end

  describe "viewing results without explicitly selecting a filter" do
    before do
      stub_request(:get, courses_url)
        .with(query: base_parameters)
        .to_return(
          body: File.new("spec/fixtures/api_responses/ten_courses.json"),
          headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
        )
    end

    it "lists only courses with all qualifications" do
      results_page.load

      expect(results_page.qualifications_filter).to have_qualifications
      expect(results_page.courses.count).to eq(10)
    end
  end

  describe "applying a filter" do
    before do
      stub_request(:get, courses_url)
        .with(query: base_parameters)
        .to_return(
          body: File.new("spec/fixtures/api_responses/ten_courses.json"),
          headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
        )
    end

    context "deselecting courses with 'qts only' qualification" do
      before do
        stub_request(:get, courses_url)
          .with(query: base_parameters.merge("filter[qualification]" => "pgce_with_qts,pgde_with_qts,pgce,pgde"))
          .to_return(
            body: File.new("spec/fixtures/api_responses/ten_courses.json"),
            headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
          )
      end

      it "list the courses" do
        results_page.load
        results_page.qualifications_filter.link.click

        expect(filter_page.heading.text).to eq("What you will get")

        filter_page.qts_only.click
        filter_page.find_courses.click

        expect(results_page.heading.text).to eq("Teacher training courses")
        expect(results_page.qualifications_filter).to have_pgde_pgce_with_qts
        expect(results_page.qualifications_filter).to have_other_qualifications

        expect(results_page.courses.count).to eq(10)
      end
    end

    context "deselecting courses that with 'pgde with qts' qualification" do
      before do
        stub_request(:get, courses_url)
          .with(query: base_parameters.merge("filter[qualification]" => "qts,pgce,pgde"))
          .to_return(
            body: File.new("spec/fixtures/api_responses/ten_courses.json"),
            headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
          )
      end

      it "list the courses" do
        results_page.load
        results_page.qualifications_filter.link.click

        expect(filter_page.heading.text).to eq("What you will get")

        filter_page.pgde_pgce_with_qts.click
        filter_page.find_courses.click

        expect(results_page.heading.text).to eq("Teacher training courses")
        expect(results_page.qualifications_filter).to have_qts_only
        expect(results_page.qualifications_filter).to have_other_qualifications

        expect(results_page.courses.count).to eq(10)
      end
    end

    context "deselecting courses with 'further education' qualification" do
      before do
        stub_request(:get, courses_url)
          .with(query: base_parameters.merge("filter[qualification]" => "qts,pgce_with_qts,pgde_with_qts"))
          .to_return(
            body: File.new("spec/fixtures/api_responses/ten_courses.json"),
            headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
          )
      end

      it "list the courses" do
        results_page.load
        results_page.qualifications_filter.link.click

        expect(filter_page.heading.text).to eq("What you will get")

        filter_page.other.click
        filter_page.find_courses.click

        expect(results_page.heading.text).to eq("Teacher training courses")
        expect(results_page.qualifications_filter).to have_pgde_pgce_with_qts
        expect(results_page.qualifications_filter).to have_qts_only

        expect(results_page.courses.count).to eq(10)
      end
    end

    context "deselecting all options" do
      it "displays an error" do
        results_page.load
        results_page.qualifications_filter.link.click

        expect(filter_page.heading.text).to eq("What you will get")

        filter_page.qts_only.click
        filter_page.pgde_pgce_with_qts.click
        filter_page.other.click
        filter_page.find_courses.click

        expect(filter_page).to have_error
      end
    end
  end

  describe "submitting without applying a filter" do
    before do
      stub_request(:get, courses_url)
        .with(query: base_parameters)
        .to_return(
          body: File.new("spec/fixtures/api_responses/ten_courses.json"),
          headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
        )

      stub_request(:get, courses_url)
        .with(query: base_parameters)
        .to_return(
          body: File.new("spec/fixtures/api_responses/ten_courses.json"),
          headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
        )
    end

    it "list the courses" do
      results_page.load
      results_page.qualifications_filter.link.click

      expect(filter_page.heading.text).to eq("What you will get")
      filter_page.find_courses.click

      expect(results_page.heading.text).to eq("Teacher training courses")
      expect(results_page.qualifications_filter).to have_qualifications

      expect(results_page.courses.count).to eq(10)
    end
  end
end
