require 'spec_helper'
require 'httparty'

class TestAPI
    include HTTParty
    base_uri 'http://deckofcardsapi.com'
end


RSpec.describe "Test", type: :request do
    before(:all) do
        @test_api = TestAPI.new()
    end

    describe "GET /index" do
        it "creates a deck" do
            response = @test_api.class.get("/api/deck/new/")
            puts response.body, response.code, response.message, response.headers.inspect
            expect(response.code).to eq(200)
        end
    end
end



