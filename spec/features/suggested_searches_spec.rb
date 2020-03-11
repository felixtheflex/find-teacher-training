require "rails_helper"

feature "suggested searches", type: :feature do
  let(:filter_page) { PageObjects::Page::ResultFilters::Location.new }
  let(:results_page) { PageObjects::Page::Results.new }
  let(:sort) { "distance" }
  let(:courses_url) do
    "http://localhost:3001/api/v3/recruitment_cycles/2020/courses"
  end
  let(:subjects_url) do
    "http://localhost:3001/api/v3/subject_areas?include=subjects"
  end
  let(:base_parameters) { results_page_parameters("sort" => sort) }
  def suggested_search_count_parameters
    base_parameters.reject do |k, _v|
      ["page[page]", "page[per_page]", "sort"].include?(k)
    end
  end

  before do
    stub_geocoder

    stub_request(:get, subjects_url)
  end

  def results_page_request(radius:, results_to_return:)
    stub_request(:get, courses_url)
      .with(query: base_parameters.merge("filter[latitude]" => 51.4980188, "filter[longitude]" => -0.1300436, "filter[radius]" => radius))
      .to_return(
        body: course_fixture_for(results: results_to_return),
        headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
    )
  end

  def suggested_search_count_request(radius:, results_to_return:)
    stub_request(:get, courses_url)
      .with(query: suggested_search_count_parameters.merge("filter[latitude]" => 51.4980188, "filter[longitude]" => -0.1300436, "filter[radius]" => radius))
      .to_return(
        body: course_fixture_for(results: results_to_return),
        headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
    )
  end

  def suggested_search_count_across_england(results_to_return:)
    stub_request(:get, courses_url)
      .with(query: suggested_search_count_parameters)
      .to_return(
        body: course_fixture_for(results: results_to_return),
        headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
    )
  end

  def course_fixture_for(results:)
    file_name = case results
                when 0
                  "empty_courses.json"
                when 2
                  "two_courses.json"
                when 4
                  "four_courses.json"
                when 10
                  "ten_courses.json"
                end

    File.new("spec/fixtures/api_responses/#{file_name}")
  end

  context "when an initial search returns no results" do
    before do
      results_page_request(radius: 10, results_to_return: 2)
      suggested_search_count_request(radius: 20, results_to_return: 2)
      suggested_search_count_request(radius: 50, results_to_return: 4)
    end

    context "when the search was filtered to a 5 mile radius" do
      before do
        results_page_request(radius: 5, results_to_return: 0)
        suggested_search_count_request(radius: 10, results_to_return: 2)
        suggested_search_count_across_england(results_to_return: 10)
      end

      it "shows links for expanded radius searches that would return more results" do
        filter_page.load
        filter_page.by_postcode_town_or_city.click
        filter_page.location_query.set "SW1P 3BT"
        filter_page.search_radius.select "5 miles"

        filter_page.find_courses.click

        expect(results_page.suggested_search_heading.text).to eq("Suggested searches")
        expect(results_page.suggested_search_description.text).to eq("You can find:")
        expect(results_page.suggested_search_links.first.text).to eq("2 courses within 10 miles")
        expect(results_page.suggested_search_links.second.text).not_to eq("2 courses within 20 miles")
        expect(results_page.suggested_search_links.second.text).to eq("4 courses within 50 miles")

        results_page.suggested_search_links.first.link.click

        expect(results_page.courses.count).to eq(2)
        expect(results_page.location_filter.name.text).to have_content("Within 10 miles of the pin")
        expect(results_page.suggested_search_links.first.text).not_to eq("2 courses within 10 miles")
        expect(results_page.suggested_search_links.first.text).not_to eq("2 courses within 20 miles")
        expect(results_page.suggested_search_links.first.text).to eq("4 courses within 50 miles")
      end

      context "where more than 2 expanded radius searches return more results than the original search" do
        before do
          suggested_search_count_request(radius: 20, results_to_return: 4)
          suggested_search_count_request(radius: 50, results_to_return: 10)
        end

        it "only shows the first 2 suggested search links" do
          filter_page.load
          filter_page.by_postcode_town_or_city.click
          filter_page.location_query.set "SW1P 3BT"
          filter_page.search_radius.select "5 miles"

          filter_page.find_courses.click
          expect(results_page.suggested_search_links.first.text).to eq("2 courses within 10 miles")
          expect(results_page.suggested_search_links.second.text).to eq("4 courses within 20 miles")
          expect(results_page.suggested_search_links.count).to eq(2)
        end
      end

      context "when the search was filtered to a 20 mile radius" do
        before do
          results_page_request(radius: 20, results_to_return: 0)
          suggested_search_count_request(radius: 50, results_to_return: 2)
          suggested_search_count_across_england(results_to_return: 4)
        end

        it "shows results from across England" do
          filter_page.load
          filter_page.by_postcode_town_or_city.click
          filter_page.location_query.set "SW1P 3BT"
          filter_page.search_radius.select "20 miles"

          filter_page.find_courses.click

          expect(results_page.suggested_search_links.first.text).to eq("2 courses within 50 miles")
          expect(results_page.suggested_search_links.second.text).to eq("4 courses across England")
        end
      end
    end

    context "no courses are found in the suggested searches" do
      before do
        results_page_request(radius: 5, results_to_return: 0)
        suggested_search_count_request(radius: 10, results_to_return: 0)
        suggested_search_count_request(radius: 20, results_to_return: 0)
        suggested_search_count_request(radius: 50, results_to_return: 0)
        suggested_search_count_across_england(results_to_return: 0)
      end

      it "doesn't show the link if there are no courses found" do
        filter_page.load
        filter_page.by_postcode_town_or_city.click
        filter_page.location_query.set "SW1P 3BT"
        filter_page.search_radius.select "5 miles"

        filter_page.find_courses.click
        expect(results_page).not_to have_suggested_search_links
      end
    end

    context "there are no results in any suggested searches" do
      before do
        results_page_request(radius: 50, results_to_return: 0)
        suggested_search_count_across_england(results_to_return: 0)
      end

      it "doesn't show the suggested searches section" do
        filter_page.load
        filter_page.by_postcode_town_or_city.click
        filter_page.location_query.set "SW1P 3BT"
        filter_page.search_radius.select "50 miles"

        filter_page.find_courses.click
        expect(results_page).not_to have_suggested_searches
      end
    end
  end

  context "a search with more than 3 results" do
    before do
      results_page_request(radius: 5, results_to_return: 10)
    end

    it "shows no links" do
      filter_page.load
      filter_page.by_postcode_town_or_city.click
      filter_page.location_query.set "SW1P 3BT"
      filter_page.search_radius.select "5 miles"

      filter_page.find_courses.click
      expect(results_page).not_to have_suggested_search_links
    end
  end

  context "a search filtered by provider with 2 results" do
    before do
      stub_request(
        :get,
        "http://localhost:3001/api/v3/recruitment_cycles/2020/providers",
      ).with(
        query: {
          "fields[providers]" => "provider_code,provider_name",
          "search" => "ACME",
        },
      ).to_return(
        body: File.new("spec/fixtures/api_responses/providers.json"),
        headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
      )

      stub_request(:get, courses_url)
        .with(
          query: base_parameters.merge("filter[provider.provider_name]" => "ACME SCITT 0"),
        )
        .to_return(
          body: File.new("spec/fixtures/api_responses/two_courses.json"),
          headers: { "Content-Type": "application/vnd.api+json; charset=utf-8" },
      )
    end

    it "doesn't show suggested searches" do
      filter_page.load
      filter_page.by_provider.click
      filter_page.provider_search.fill_in(with: "ACME")
      filter_page.find_courses.click

      expect(results_page).not_to have_suggested_search_links
    end
  end
end