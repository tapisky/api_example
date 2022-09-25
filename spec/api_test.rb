require 'spec_helper'
require 'httparty'

class Test
    include HTTParty
    base_uri 'http://deckofcardsapi.com/api/deck'
end

RSpec.describe Test do
    before(:all) do
        @test = Test.new
        @deck_ids = []
    end

    shared_examples "draw cards from pile" do |num_cards,pile_name|
        it "draws cards from pile" do
            # get pile remaining cards first so we can check later
            list_response = @test.class.get("/#{@deck_ids[0]}/pile/#{pile_name}/list/")
            expect(list_response.code.to_i).to be(200)
            list_json = JSON.parse(list_response.body)
            remaining_before = list_json["piles"][pile_name]["remaining"].to_i
            # then, let's draw cards from pile and check remaining
            response = @test.class.get("/#{@deck_ids[0]}/pile/#{pile_name}/draw/?count=#{num_cards}")
            expect(response.code.to_i).to be(200)
            json = JSON.parse(response.body)
            expect(json["success"]).to eq(true)
            expect(json["deck_id"]).to eq(@deck_ids[0])
            expect(json["piles"][pile_name]["remaining"]).to eq(remaining_before - num_cards)
        end
    end

    it "checks 'creates a new deck'" do
        response = @test.class.get("/new/")
        expect(response.code.to_i).to be(200)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["shuffled"]).to eq(false)
        expect(json["remaining"]).to eq(52)
        @deck_ids.push(json["deck_id"])
    end

    it "shuffles deck" do
        response = @test.class.get("/#{@deck_ids[0]}/shuffle/?deck_count=1")
        expect(response.code.to_i).to be(200)
        json = JSON.parse(response.body)
        expect(json["deck_id"]).to eq(@deck_ids[0])
        expect(json["success"]).to eq(true)
        expect(json["shuffled"]).to eq(true)
        expect(json["remaining"]).to eq(52)
    end

    it "draws 3 cards from deck" do
        response = @test.class.get("/#{@deck_ids[0]}/draw/?count=3")
        expect(response.code.to_i).to be(200)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["deck_id"]).to eq(@deck_ids[0])
        expect(json["remaining"]).to eq(49)
        expect(json["cards"].size).to eq(3)
    end

    it 'makes 2 piles with 5 cards each from deck' do
        ["pile1", "pile2"].each do |pile|
            # draw cards and get card codes which are needed to create a pile
            draw_response = @test.class.get("/#{@deck_ids[0]}/draw/?count=5")
            expect(draw_response.code.to_i).to be(200)
            draw_json = JSON.parse(draw_response.body)
            card_codes = []
            draw_json["cards"].each { |card| card_codes.push(card["code"]) }
            # Create pile and check
            pile_response = @test.class.get("/#{@deck_ids[0]}/pile/#{pile}/add/?cards=#{cards=card_codes.join(",")}")
            expect(pile_response.code.to_i).to be(200)
            pile_json = JSON.parse(pile_response.body)
            expect(pile_json["deck_id"]).to eq(@deck_ids[0])
            expect(pile_json["success"]).to eq(true)
            expect(pile_json["remaining"]).to eq(draw_json["remaining"])
            expect(pile_json["piles"][pile]["remaining"]).to eq(5)
        end
    end

    it "lists cards in pile1 and pile2" do
        ["pile1", "pile2"].each do |pile|
            response = @test.class.get("/#{@deck_ids[0]}/pile/#{pile}/list/")
            expect(response.code.to_i).to be(200)
            json = JSON.parse(response.body)
            expect(json["success"]).to eq(true)
            expect(json["deck_id"]).to eq(@deck_ids[0])
            expect(json["piles"][pile]["remaining"]).to eq(5)
            expect(json["piles"][pile]["cards"].size).to eq(5)
        end
    end

    it "shuffles pile1" do
        response = @test.class.get("/#{@deck_ids[0]}/pile/pile1/shuffle/")
        expect(response.code.to_i).to be(200)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["deck_id"]).to eq(@deck_ids[0])
        expect(json["piles"]["pile1"]["remaining"]).to eq(5)
    end

    include_examples "draw cards from pile", 2, "pile1"
    include_examples "draw cards from pile", 3, "pile2"

end
