require 'spec_helper'
require 'httparty'

class Test
    include HTTParty
    attr_accessor :deck_id

    base_uri 'http://deckofcardsapi.com/api/deck'

    def initialize
        @deck_id = nil
    end
end

def json(response)
    return JSON.parse(response.body)
end

RSpec.describe "API Test" do
    before(:all) do
        @test = Test.new
    end

    shared_examples "draw cards from pile" do |num_cards,pile_name|
        it "draws cards from pile" do
            # get pile remaining cards first so we can check later
            list_response = @test.class.get("/#{@test.deck_id}/pile/#{pile_name}/list/")
            expect(list_response.code.to_i).to be(200)
            remaining_before = json(list_response)["piles"][pile_name]["remaining"].to_i
            # then, let's draw cards from pile and check remaining
            response = @test.class.get("/#{@test.deck_id}/pile/#{pile_name}/draw/?count=#{num_cards}")
            expect(response.code.to_i).to be(200)
            expect(json(response)["success"]).to eq(true)
            expect(json(response)["deck_id"]).to eq(@test.deck_id)
            expect(json(response)["piles"][pile_name]["remaining"]).to eq(remaining_before - num_cards)
        end
    end

    it "creates a new deck" do
        response = @test.class.get("/new/")
        expect(response.code.to_i).to be(200)
        expect(json(response)["success"]).to eq(true)
        expect(json(response)["shuffled"]).to eq(false)
        expect(json(response)["remaining"]).to eq(52)
        # Take note of 'deck_id' to use in the other examples
        @test.deck_id = json(response)["deck_id"]
    end

    it "shuffles deck" do
        response = @test.class.get("/#{@test.deck_id}/shuffle/?deck_count=1")
        expect(response.code.to_i).to be(200)
        expect(json(response)["deck_id"]).to eq(@test.deck_id)
        expect(json(response)["success"]).to eq(true)
        expect(json(response)["shuffled"]).to eq(true)
        expect(json(response)["remaining"]).to eq(52)
    end

    it "draws 3 cards from deck" do
        response = @test.class.get("/#{@test.deck_id}/draw/?count=3")
        expect(response.code.to_i).to be(200)
        expect(json(response)["success"]).to eq(true)
        expect(json(response)["deck_id"]).to eq(@test.deck_id)
        expect(json(response)["remaining"]).to eq(49)
        expect(json(response)["cards"].size).to eq(3)
    end

    it 'makes 2 piles with 5 cards each from deck' do
        ["pile1", "pile2"].each do |pile|
            # draw cards and get card codes which are needed to create a pile
            draw_response = @test.class.get("/#{@test.deck_id}/draw/?count=5")
            expect(draw_response.code.to_i).to be(200)
            card_codes = []
            json(draw_response)["cards"].each { |card| card_codes.push(card["code"]) }
            # Create pile and check
            pile_response = @test.class.get("/#{@test.deck_id}/pile/#{pile}/add/?cards=#{cards=card_codes.join(",")}")
            expect(pile_response.code.to_i).to be(200)
            expect(json(pile_response)["deck_id"]).to eq(@test.deck_id)
            expect(json(pile_response)["success"]).to eq(true)
            expect(json(pile_response)["remaining"]).to eq(json(draw_response)["remaining"])
            expect(json(pile_response)["piles"][pile]["remaining"]).to eq(5)
        end
    end

    it "lists cards in pile1 and pile2" do
        ["pile1", "pile2"].each do |pile|
            response = @test.class.get("/#{@test.deck_id}/pile/#{pile}/list/")
            expect(response.code.to_i).to be(200)
            expect(json(response)["success"]).to eq(true)
            expect(json(response)["deck_id"]).to eq(@test.deck_id)
            expect(json(response)["piles"][pile]["remaining"]).to eq(5)
            expect(json(response)["piles"][pile]["cards"].size).to eq(5)
        end
    end

    it "shuffles pile1" do
        response = @test.class.get("/#{@test.deck_id}/pile/pile1/shuffle/")
        expect(response.code.to_i).to be(200)
        expect(json(response)["success"]).to eq(true)
        expect(json(response)["deck_id"]).to eq(@test.deck_id)
        expect(json(response)["piles"]["pile1"]["remaining"]).to eq(5)
    end

    include_examples "draw cards from pile", 2, "pile1"
    include_examples "draw cards from pile", 3, "pile2"

end
