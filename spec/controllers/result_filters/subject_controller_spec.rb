require "rails_helper"

RSpec.describe ResultFilters::SubjectController do
  describe "#new" do
    context "when subjects is a comma delimited string" do
      it "returns a 200" do
        stub_request(:get, "http://localhost:3001/api/v3/subject_areas?include=subjects")
           .with(
             headers: {
               "Accept" => "application/vnd.api+json",
               "Accept-Encoding" => "gzip,deflate",
               "Content-Type" => "application/vnd.api+json",
               "User-Agent" => "Faraday v0.17.3",
             },
           ).to_return(status: 200, body: "", headers: {})

        get :new, params: { subjects: "38,29" }
        expect(response).to be_successful
      end
    end
  end
end
